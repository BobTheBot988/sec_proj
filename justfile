alias id := installDependencies

installDependencies:
    forge install foundry-rs/forge-std
    forge install OpenZeppelin/openzeppelin-foundry-upgrades
    forge install OpenZeppelin/openzeppelin-contracts-upgradeable
    forge install a16z/halmos-cheatcodes
build: installDependencies
    forge b

test: build
    forge t && halmos 
