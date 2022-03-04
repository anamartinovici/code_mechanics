This repository uses a `Makefile` to improve numerical reproducibility.

If you want to learn more about `Make`, these are some resources you can use:

- https://merely-useful.tech/py-rse/automate.html

- https://stat545.com/make-test-drive.html

- https://makefiletutorial.com/

- https://www.gnu.org/software/make/manual/html_node/Simple-Makefile.html#Simple-Makefile

# How to:

## check if you have make available

- Open a terminal and type:

`which make`

If you get a message that says "which: no make" and then a series of paths, then you either do not have make installed, or make is not added to Path (Environment Variables on Windows).

If you get a message that shows a path to "bin/make", then you have make installed and added to Path, and you can continue using make in this project.

On my personal laptop (Ana) it works if I use `powershell` as a terminal.

Then, typing `make test_make` in the terminal checks if make can be used. If `success_test_make.txt` is created in the root directory of the git repo, then open the file and enjoy the success :)



