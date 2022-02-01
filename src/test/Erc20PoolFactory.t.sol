// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "ds-test/test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../Erc20Pool.sol";
import "../Erc20PoolFactory.sol";

contract PoolFactoryTest is DSTest {
    Erc20PoolFactory internal factory;
    ERC20 internal token;

    function setUp() public {
        factory = new Erc20PoolFactory();
        token = new ERC20("Test", "T");
    }

    function test_deploy() public {
        Erc20Pool pool = factory.deployPool(token);

        assertEq(address(token), address(pool.UNDERLYING()));
    }

    function testFail_deploy_same_pool_twice() public {
        factory.deployPool(token);
        factory.deployPool(token);
    }

    function test_predict_deployed_address() public {
        address predictedAddress = factory.calculatePoolAddress(token);

        assert(false == factory.isPoolDeployed(Erc20Pool(predictedAddress)));

        Erc20Pool pool = factory.deployPool(token);

        assertEq(address(pool), predictedAddress);
        assert(true == factory.isPoolDeployed(Erc20Pool(predictedAddress)));
    }
}
