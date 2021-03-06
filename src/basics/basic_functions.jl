function next_time_period(TIME::Timer, QC::Array{QuayCrane, 1}, CTS::Constants)
    min_unit = 5
    TIME.period += min_unit
    l = Array{Int, 1}()
    #update all QC atributtes
    for qc in QC
        #update QC position
        if qc.status == "moving"
            if  qc.next_bay < qc.current_bay
                qc.current_bay -= min_unit/CTS.tt
            elseif qc.next_bay > qc.current_bay
                qc.current_bay += min_unit/CTS.tt
            end
            if abs(qc.current_bay-round(qc.current_bay)) < 1e-10
                qc.current_bay = round(qc.current_bay)
            end
        end
        #update QC time left and status
        if qc.time_left > min_unit
            qc.time_left -= min_unit
        elseif qc.time_left == min_unit
            if length(qc.task_buffer) > 0
                if qc.status == "loading"
                    if qc.current_bay == qc.task_buffer[1].b
                        qc.time_left = 2*qc.task_buffer[1].t
                        qc.status = "loading"
                        deleteat!(qc.task_buffer, 1)
                    else
                        qc.time_left = travel_time(qc.current_bay, qc.task_buffer[1].b, CTS)
                        qc.next_bay = qc.task_buffer[1].b
                        qc.status = "moving"
                    end
                elseif qc.status == "moving" || qc.status == "waiting to load"
                    if qc.task_buffer[1].t ==0
                        qc.status = "idle"
                    else
                        qc.status = "loading"
                    end
                    qc.time_left = 2*qc.task_buffer[1].t
                    deleteat!(qc.task_buffer, 1)
                elseif qc.status == "waiting to move"
                    qc.time_left = travel_time(qc.current_bay, qc.task_buffer[1].b, CTS)
                    qc.next_bay = qc.task_buffer[1].b
                    qc.status = "moving"
                end
            else
                qc.time_left = 0
                qc.status = "idle"
                qc.task_buffer = Array{LTask, 1}()
            end
        elseif qc.time_left == 0
            qc.time_left = 0
            qc.status = "idle"
        end
        if qc.status == "idle"
            push!(l, qc.q)
        end
    end
    TIME.available_cranes = l
end

function travel_time(current_bay::Number, target_bay::Int, CTS::Constants)
    return(round(abs(current_bay - target_bay)*CTS.tt))
end


function get_qc_last_time(q::Int, LS::LoadingSequence)
    for t in reverse(LS.order)
        if t.qc == q
            return(t.start_time + 2*t.task.t)
        end
    end
end

function get_qc_start_time(q::Int, LS::LoadingSequence)
    for t in LS.order
        if t.qc == q
            return(t.start_time)
        end
    end
end

function get_qc_last_bay(q::Int, LS::LoadingSequence)
    for t in reverse(LS.order)
        if t.qc == q
            return(t.task.b)
        end
    end
    return(0)
end
function get_qc_first_bay(q::Int, LS::LoadingSequence)
    for t in LS.order
        if t.qc == q
            return(t.task.b)
        end
    end
end

function update_quay_crane(TIME::Timer, QC::Array{QuayCrane, 1}, task::LTask, q::Int, CTS::Constants)
    if abs(QC[q].current_bay-round(QC[q].current_bay)) < 1e-10
        QC[q].current_bay = round(QC[q].current_bay)
    end
    if task.b == QC[q].current_bay
        QC[q].time_left = 2*task.t
        QC[q].status = "loading"
        QC[q].next_bay = QC[q].current_bay
    else
        QC[q].time_left = travel_time(QC[q].current_bay, task.b, CTS)
        QC[q].status = "moving"
        QC[q].next_bay = task.b
        if task.c != 0 && task.p != 0
            push!(QC[q].task_buffer, task)
        end
    end
end

function update_load_seq(TIME::Timer, LS::LoadingSequence, QC::Array{QuayCrane, 1}, task::LTask, q::Int, CTS::Constants)
    LS.len += 1
    LS.tasks_left -= 1
    start_time = TIME.period + travel_time(QC[q].current_bay, task.b, CTS)
    push!(LS.order, (task=task, start_time=start_time, qc=q))
    push!(LS.filled_pos, task.p)
    push!(LS.loaded_cont,task.c)
end

function update_wait_quay_crane(TIME::Timer, QC::Array{QuayCrane, 1}, task::LTask, q::Int, move_q::Int, move_bay::Int, CTS::Constants)
    if abs(QC[q].current_bay-round(QC[q].current_bay)) < 1e-10
        QC[q].current_bay = round(QC[q].current_bay)
    end
    if task.b == QC[q].current_bay
        QC[q].time_left = travel_time(QC[move_q].current_bay, QC[move_q].next_bay, CTS)
        QC[q].status = "waiting to load"
        QC[q].next_bay = QC[q].current_bay
        push!(QC[q].task_buffer, task)
    elseif travel_time(QC[q].current_bay, task.b, CTS) >= travel_time(QC[move_q].current_bay, QC[move_q].next_bay, CTS)
        QC[q].time_left = travel_time(QC[q].current_bay, task.b, CTS)
        QC[q].status = "moving"
        QC[q].next_bay = task.b
        if task.t != 0 && task.p !=0
            push!(QC[q].task_buffer, task)
        end
    else
        QC[q].time_left = travel_time(QC[move_q].current_bay, QC[move_q].next_bay, CTS) - travel_time(QC[q].current_bay, task.b, CTS)
        QC[q].status = "waiting to move"
        QC[q].next_bay = task.b
        if task.t != 0 && task.p !=0
            push!(QC[q].task_buffer, task)
        end
    end
end

function update_wait_load_seq(TIME::Timer, LS::LoadingSequence, QC::Array{QuayCrane, 1}, task::LTask, q::Int, move_q::Int, move_bay::Int, CTS::Constants)
    LS.len += 1
    LS.tasks_left -= 1
    start_time = TIME.period + max(travel_time(QC[q].current_bay, task.b, CTS), travel_time(QC[move_q].current_bay, QC[move_q].next_bay, CTS))
    push!(LS.order, (task=task, start_time=start_time, qc=q))
    push!(LS.filled_pos, task.p)
    push!(LS.loaded_cont,task.c)
end

function update_dummy_load_seq(TIME::Timer, LS::LoadingSequence, QC::Array{QuayCrane, 1}, move_q::Int, move_bay::Int, CTS::Constants)
    start_time = TIME.period + travel_time(QC[move_q].current_bay, move_bay, CTS)
    push!(LS.order, (task = LTask(0, move_bay, 0, 0), start_time=start_time, qc=move_q))
end

function add_task(task::LTask, q::Int, TIME::Timer, LS::LoadingSequence, QC::Array{QuayCrane, 1}, CTS::Constants)
    update_load_seq(TIME, LS, QC, task, q, CTS)
    update_quay_crane(TIME, QC, task, q, CTS)
    deleteat!(TIME.available_cranes, findall(x->x==q, TIME.available_cranes))
end

function add_task_move(task::LTask, q::Int, move_q::Int, move_bay::Int, move_status::String, LS::LoadingSequence, TIME::Timer, QC::Array{QuayCrane, 1}, CTS::Constants)
    if move_status == "idle"
        update_quay_crane(TIME, QC, LTask(0, move_bay, 0, 0), move_q, CTS)
        update_dummy_load_seq(TIME, LS, QC, move_q, move_bay, CTS)
        deleteat!(TIME.available_cranes, findall(x->x==move_q, TIME.available_cranes))
        update_wait_quay_crane(TIME, QC, task, q, move_q, move_bay, CTS)
        update_wait_load_seq(TIME, LS, QC, task, q, move_q, move_bay, CTS)
        deleteat!(TIME.available_cranes, findall(x->x==q, TIME.available_cranes))
    elseif move_status == "moving"
        update_wait_quay_crane(TIME, QC, task, q, move_q, move_bay, CTS)
        update_wait_load_seq(TIME, LS, QC, task, q, move_q, move_bay, CTS)
        deleteat!(TIME.available_cranes, findall(x->x==q, TIME.available_cranes))
    end
end

function add_move(move_q::Int, move_bay::Int, LS::LoadingSequence, TIME::Timer, QC::Array{QuayCrane, 1}, CTS::Constants)
    update_quay_crane(TIME, QC, LTask(0, move_bay, 0, 0), move_q, CTS)
    update_dummy_load_seq(TIME, LS, QC, move_q, move_bay, CTS)
    deleteat!(TIME.available_cranes, findall(x->x==move_q, TIME.available_cranes))
end
