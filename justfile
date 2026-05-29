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

halmos f="":
    halmos --loop 10 --solver-threads 16 {{ f }}

halmos-c contract f="":
    halmos --match-contract {{ contract }} --loop 10 --solver-threads 16 --function check {{ f }}

echidna:
    echidna . --contract TaxpayerTest --config echidna.yaml && 
    echidna . --contract LotteryTest --config echidna.yaml

alias am := add-mcp
alias as := add-skill
alias d := debug

add-skill:
    npx skills install openzeppelin/openzeppelin-skills@develop-secure-contracts

install:
    forge install foundry-rs/forge-std && \
    forge install OpenZeppelin/openzeppelin-foundry-upgrades &&  \
    forge install OpenZeppelin/openzeppelin-contracts-upgradeable

add-mcp:
    claude mcp add --transport stdio solidity-synthesis -- mcp_synth --cwd . --project auction-deepseek-flash --invariants 1
clean:
    forge clean
run:
    claude --append-system-prompt-file prompt.md --dangerously-skip-permissions
debug:
    claude --debug mcp --debug-file /tmp/claude_debug.log --append-system-prompt-file prompt.md --dangerously-skip-permissions
