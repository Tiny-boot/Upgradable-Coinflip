// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Coinflip} from "../src/Coinflip.sol";
import {CoinflipV2} from "../src/CoinflipV2.sol";
import {UUPSProxy} from "../src/Proxy.sol";
import {DauphineToken} from "../src/DauphineToken.sol";

contract CoinflipUpgradeTest is Test {
    Coinflip public game;
    CoinflipV2 public gameV2;
    DauphineToken public token;
    UUPSProxy public proxy;

    Coinflip public wrappedV1;
    CoinflipV2 public wrappedV2;

    address owner = vm.addr(0x1);
    address player = address(0x1234); // Dummy player address

    function setUp() public {
        // Set deployer to know address

        vm.startPrank(owner);
        // Initialize both versions of the contract
        token = new DauphineToken(owner);
        
        game = new Coinflip();
        gameV2 = new CoinflipV2();

        // Launch the proxy with V1 implementation
        proxy = new UUPSProxy(address(game), abi.encodeWithSignature("initialize(address)", owner));

        // We need to cheat here a litte because the coin flip game is not deployed and the proxy
        // will not know how to access the game unless wrapped.
        wrappedV1 = Coinflip(address(proxy));
        // Initialize the CoinflipV2 contract with the owner and token address
        wrappedV1.upgradeToAndCall(
            address(gameV2),
            abi.encodeWithSignature("initialize(address,address)", owner, address(token))
        );

        // Wrap the proxy to interact with V2
        wrappedV2 = CoinflipV2(address(proxy));

        // Set CoinflipV2 as the minter in the DauphineToken contract
        token.setMinter(address(wrappedV2));
        console2.log("CoinflipV2 set as minter in DauphineToken");

        vm.stopPrank();
    }

    /////////////////////////////////////////////////////
    ////      Test if V1 is initialized correctly    ////
    /////////////////////////////////////////////////////
    function test_V1InitialSeed() public {
        assertEq(wrappedV1.seed(), "It is a good practice to rotate seeds often in gambling");
    }

    /////////////////////////////////////////////////////
    ////  Test if proxy is pointing to V1 by         ////
    ////              winning predictably            ////
    /////////////////////////////////////////////////////

    function test_V1Win() public {
        vm.startPrank(player);

        assertEq(wrappedV1.UserInput([1, 0, 0, 0, 1, 1, 1, 1, 0, 1], player), true);
       
        uint256 playerBalance = token.balanceOf(player);
        assertEq(playerBalance, 5 * 10 ** token.decimals());

        vm.stopPrank();
    }

    /////////////////////////////////////////////////////
    ////          Test seed rotation in V2           ////
    /////////////////////////////////////////////////////
    function test_Rotation() public {
        vm.startPrank(owner);

        // Upgrade the proxy to V2 and wrap it
        wrappedV1.upgradeToAndCall(address(gameV2), "");
        wrappedV2 = CoinflipV2(address(proxy));

        wrappedV2.seedRotation("1234567890", 5);
        assertEq(wrappedV2.seed(), "6789012345");
        vm.stopPrank();

    }
}
