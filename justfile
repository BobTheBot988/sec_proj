alias b := build
alias r := run
build:
    forge build

test f="":
    forge test {{ f }}

test-v f="":
    forge test -vvv {{ f }}

test-vv f="":
    forge test -vvvv {{ f }}

test-s suite:
    forge test --match-contract {{ suite }} -vvv

test-t test:
    forge test --match-test {{ test }} -vvvv

rerun:
    forge test --rerun

alias b := build
alias r := run
build:
    forge build

halmos f="":
    halmos --loop 10 --solver-threads 16 {{ f }}

halmos-c contract f="":
    halmos --match-contract {{ contract }} --loop 10 --solver-threads 16 --function check {{ f }}

echidna:
    echidna . --contract TaxpayerTest --config echidna.yaml && 
    echidna . --contract LotteryTest --config echidna.yaml
alias b := build
alias r := run
build:
    forge build

halmos f="":
    halmos --loop 10 --solver-threads 16 {{ f }}

halmos-c contract:
    halmos --match-contract {{ contract }} --loop 10 --solver-threads 16

echidna:
    echidna . --contract TaxpayerTest --config echidna.yaml && 
    echidna . --contract LotteryTest --config echidna.yaml

clean:
    forge clean
run:
    claude --append-system-prompt-file prompt.md --dangerously-skip-permissions
halmos f="":
    halmos --loop 10 --solver-threads 16 {{ f }}

halmos-c contract:
    halmos --match-contract {{ contract }} --loop 10 --solver-threads 16

echidna:
    echidna . --contract TaxpayerTest --config echidna.yaml && 

clean:
    forge clean
run:
    claude --append-system-prompt-file prompt.md --dangerously-skip-permissions
