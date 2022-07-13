# Config Driven Data Pipelines

**Build:**

## Getting Started

These instructions will allow you to build the Webapi component on your local machine for development and testing purposes.

This code is built using the [Cake](https://cakebuild.net/) build framework and [Maven](https://maven.apache.org/) as packet manager. It can be built using locally installed components or a containerized environment.

The recommended editor for working on this code is [Visual Studio Code](https://code.visualstudio.com/Download). The recommended extensions can be viewed by running the VSCode command "Extensions: Show Recommended Extensions". Once the Cake extension is installed, run the VSCode command "Cake: Install intellisense support" to make it easier to work on the build scripts.

VSCode commands can be executed on _command pallete_ which can be launched using Ctrl+Shift+P key combination.

### Containerized Enviornments



### Building on Windows

Install the following prerequisites:

* [DotNetCore SDK](https://www.microsoft.com/net/download)
* [DotNet Framework 4.7.2](https://dotnet.microsoft.com/download/dotnet-framework-runtime)
* [Python version 3.7](https://www.python.org/downloads/)
* [pip version 19.1.1](https://pip.pypa.io/en/stable/installing/)


#### Build on windows locally

On domain joined developer machines, Enterprise IT has disabled unsigned Powershell script execution. 
As a workaround there is a batch file that calls the required powershell file which is executed on the build machine.

```
.\bootstrap.bat
```

#### Build without build scripts

```cmd
pip install -r ./src/requirements.txt --user
python ./src/setup.py build
```

### Building on Linux and Mac using Docker

Install the following prerequisites:

* Docker version 18+
* Powershell Core [Linux](<https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell-core-on-linux?view=powershell-6>)/[Mac](<https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-6>)

Then run the build

```cmd
pwsh bootstrap.ps1
```

### Building on Linux and Mac using Local Installs

Install the following prerequisites:

* Powershell Core [Linux](<https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell-core-on-linux?view=powershell-6>)/[Mac](<https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos?view=powershell-6>)
* Python version 3.7 [Linux](https://www.python.org/downloads/source/)/[Mac](https://www.python.org/downloads/mac-osx/)
* Pip version 19.1.1 [Linux/Mac](https://pip.pypa.io/en/stable/installing/)


### Build wheel solution packages (*nix)

```bash
ls -ld src/cddp_solution tests/hon*/ | awk '{split($0, array); print array[9]}' | xargs -n 1 python -m build  -w
```


### Running the API template Locally

#### From IDE

ToDo

#### From Command Line

```cmd
pip install -r ./src/requirements.txt --user
python ./src/setup.py build
python ./src/init_app.py --host 0.0.0.0
```

#### From Docker

1. Run `.\bootstrap.ps1` to download and execute the build scripts, perform Build and Package
2. Run `.\bootstrap.ps1 -Target Publish` to generate the docker image of the deployable application
3. From a command/powershell prompt you should be able to see your newly created image. It should look something like this:

    ```shell

    $ docker image ls
    REPOSITORY           TAG        IMAGE ID            CREATED             SIZE

    <bitbucket-repo-name> 0.1.0     2d2cfc645c50       2 hours ago         1.45GB

    ```
4. Create and run the docker container from the image as follows:

    ```shell
      docker run -it --rm -p 80:8000/tcp --name <bitbucket-repo-name>.0.1.0 <bitbucket-repo-name>
    ```