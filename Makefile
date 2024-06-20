# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env && source ./tests/forge/invariants/scenarios/scenario-${SCENARIO}.sh

CONTRACT_EXCLUDES="RegressionTest|Panic|RealWorld|Trading"
TEST_EXCLUDES="testLoad|invariant|test_regression"

all: clean install build

# Clean the repo
clean   :; forge clean

# Install the Modules
install :; git submodule update --init --recursive

# Builds
build   :; forge clean && forge build

# Unit Tests
test                            :; forge test --no-match-test ${TEST_EXCLUDES} --nmc ${CONTRACT_EXCLUDES}  # --ffi # enable if you need the `ffi` cheat code on HEVM
test-with-gas-report            :; forge test --no-match-test ${TEST_EXCLUDES} --nmc ${CONTRACT_EXCLUDES} --gas-report # --ffi # enable if you need the `ffi` cheat code on HEVM

# Gas Load Tests
test-load                       :; forge test --match-test testLoad --gas-report

# Invariant Tests
test-invariant-all                       :; forge t --mt invariant --nmc ${CONTRACT_EXCLUDES}
test-invariant-erc20                     :; forge t --mt invariant --nmc ${CONTRACT_EXCLUDES} --mc ERC20
test-invariant-erc721                    :; forge t --mt invariant --nmc ${CONTRACT_EXCLUDES} --mc ERC721
test-invariant-position-erc20            :; forge t --mt invariant --nmc ${CONTRACT_EXCLUDES} --mc ERC20PoolPosition 
test-invariant-position-erc721           :; forge t --mt invariant --nmc ${CONTRACT_EXCLUDES} --mc ERC721PoolPosition
test-invariant                           :; forge t --mt ${MT} --nmc RegressionTest
test-invariant-erc20-precision           :; ./tests/forge/invariants/test-invariant-erc20-precision.sh
test-invariant-erc721-precision          :; ./tests/forge/invariants/test-invariant-erc721-precision.sh
test-invariant-erc20-buckets             :; ./tests/forge/invariants/test-invariant-erc20-buckets.sh
test-invariant-erc721-buckets            :; ./tests/forge/invariants/test-invariant-erc721-buckets.sh
test-invariant-position-erc20-precision  :; ./tests/forge/invariants/test-invariant-position-erc20-precision.sh
test-invariant-position-erc721-precision :; ./tests/forge/invariants/test-invariant-position-erc721-precision.sh

# Real-world simulation scenarios
test-rw-simulation-erc20        :; FOUNDRY_INVARIANT_SHRINK_SEQUENCE=false RUST_LOG=forge=info,foundry_evm=info,ethers=info forge t --mt invariant_all_erc20 --mc RealWorldScenario
test-rw-simulation-erc721       :; FOUNDRY_INVARIANT_SHRINK_SEQUENCE=false RUST_LOG=forge=info,foundry_evm=info,ethers=info forge t --mt invariant_all_erc721 --mc RealWorldScenario

# Liquidations load test scenarios
test-liquidations-load-erc20     :; FOUNDRY_INVARIANT_SHRINK_SEQUENCE=false RUST_LOG=forge=info,foundry_evm=info,ethers=info forge t --mt invariant_all_erc20 --mc PanicExitERC20
test-liquidations-load-erc721    :; FOUNDRY_INVARIANT_SHRINK_SEQUENCE=false RUST_LOG=forge=info,foundry_evm=info,ethers=info forge t --mt invariant_all_erc721 --mc PanicExitERC721

# Swap tokens load test scenarios
test-swap-load-erc20             :; FOUNDRY_INVARIANT_SHRINK_SEQUENCE=false RUST_LOG=forge=info,foundry_evm=info,ethers=info forge t --mt invariant_all_erc20 --mc TradingERC20

# Regression Tests
test-regression-all             : test-regression-erc20 test-regression-erc721 test-regression-prototech
test-regression-erc20           :; forge t --mt test_regression --mc ERC20 --nmc "RealWorldRegression|Prototech"
test-regression-erc721          :; forge t --mt test_regression --mc ERC721 --nmc "RealWorldRegression|Prototech"
test-regression-position        :; forge t --mt test_regression --mc Position --nmc "RealWorldRegression|Prototech"
test-regression-prototech       :; forge t --mt test_regression --mc Prototech
test-regression-rw              :; forge t --mt test_regression --mc RealWorldRegression
test-regression                 :; forge t --mt ${MT}

# Coverage
coverage                        :; forge coverage --no-match-test "testLoad|invariant"

# Certora
certora-erc721-permit          :; $(if $(CERTORAKEY),, @echo "set certora key"; exit 1;) PATH=~/.solc-select/artifacts/solc-0.8.14:~/.solc-select/artifacts:${PATH} certoraRun --solc_map PermitERC721Harness=solc-0.8.14,Auxiliar=solc-0.8.14,SignerMock=solc-0.8.14 --optimize_map PermitERC721Harness=500,Auxiliar=0,SignerMock=0 --rule_sanity basic certora/harness/PermitERC721Harness.sol certora/Auxiliar.sol certora/SignerMock.sol --verify PermitERC721Harness:certora/PermitERC721.spec --multi_assert_check $(if $(short), --short_output,)

# Generate Gas Snapshots
snapshot :; forge clean && forge snapshot

analyze:
		slither src/. ; slither src/libraries/external/.


# Deployment
deploy-contracts:
	forge script script/deploy.s.sol \
		--rpc-url ${ETH_RPC_URL} --sender ${DEPLOY_ADDRESS} --keystore ${DEPLOY_KEY} --broadcast -vvv --verify

# forge verify-contract --chain-id 59141 --watch 0xd72A448C3BC8f47EAfFc2C88Cf9aC9423Bfb5067 ERC20PoolFactory --constructor-args $(cast abi-encode "constructor(address)" 0x6644E78d39859C0d93E6c435b9Cf34D74ee1CEe3)
# forge verify-contract --chain-id 59141 --watch 0x0c1Fa8D707dFb57551efa21C16255BEAb13F5bCD ERC721PoolFactory --constructor-args $(cast abi-encode "constructor(address)" 0x6644E78d39859C0d93E6c435b9Cf34D74ee1CEe3)
# forge verify-contract --chain-id 59141 --watch 0x3AFcEcB6A943746eccd72eb6801E534f8887eEA1 PoolInfoUtils
# forge verify-contract --chain-id 59141 --watch 0x38d55d1f2100dB1423C4907Aa907D47B4670d5EF PoolInfoUtilsMulticall --constructor-args $(cast abi-encode "constructor(address)" 0x3AFcEcB6A943746eccd72eb6801E534f8887eEA1)
# forge verify-contract --chain-id 59141 --watch 0x083BDB49dBA6f5A225a20893e043220526DeCf54 PositionManager --constructor-args $(cast abi-encode "constructor(address,address)" 0xd72A448C3BC8f47EAfFc2C88Cf9aC9423Bfb5067 0x0c1Fa8D707dFb57551efa21C16255BEAb13F5bCD)