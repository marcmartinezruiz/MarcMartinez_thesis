# Solving the Ship Loading and Crane Split Problem

This solution method has been developed to solve the Ship Loading and Crane Split Problem. In order to correctly execute the program it is necessary to include the listed packages in the `Project.toml` and `Manifest.toml` files (either manually or by activating the preset environment). 

### Using the Default Tutorial Packages

The files `Project.toml` and `Manifest.toml` contain the information about versions of the default tutorial packages that we know work well. These packages can be _activated_ by running the following code in the `MarcMartinez_thesis-master` folder:
```
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
```
### Running the program

After making sure that the computer has all the required packages, the next step is to include the `main.jl` file. To do that, the user must initiate Julia inside the `MarcMartinez_thesis-master/src/basics/` directory. If you have just activated the preset environment, you should first exit Julia and initiate it again in the correct directory. Once done, you can just code the following:
```
include("main.jl")
```
To trigger a specific dataset, the user must change the content of the `main.jl` file. Line 32 has to be commented and line 33 uncomented. The name of the desired file has to replace `500C_100Type_Scattered_4QC.txt`.

<ins>Note:</ins> Even though it is possible to run the solution method using a single thread, it is currently set to use 8 threads by default, so Julia should be initiated like this:
```
julia -p 8
```

### Contact
If you have any doubts or suggestions regarding the solution method, do not hesitate to contact me at _mmartinezruiz96@gmail.com_
