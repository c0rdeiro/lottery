//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subscriptionId, ) = createSubscription(vrfCoordinator);

        return (subscriptionId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        console.log(
            "Creating subscription on VRF Coordinator at address:",
            vrfCoordinator
        );
        vm.startBroadcast();
        // Create a subscription
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        return (subscriptionId, vrfCoordinator);
    }

    function run() external {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 private constant AMOUNT_TO_FUND = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken
    ) public {
        console.log(
            "Funding subscription with ID:",
            subscriptionId,
            "on VRF Coordinator at address:",
            vrfCoordinator
        );
        console.log("CHAIN ID:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            // Fund the subscription with 1 LINK
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                1e18 // 1 LINK
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            console.log(
                "Wallet balance before funding:",
                msg.sender,
                LinkToken(linkToken).balanceOf(msg.sender)
            );
            console.log("LINK token address:", address(linkToken));
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                AMOUNT_TO_FUND,
                abi.encode(subscriptionId)
            );

            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerWithConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;

        addConsumer(vrfCoordinator, subscriptionId, mostRecentlyDeployed);
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subscriptionId,
        address contractToAddToVrf
    ) public {
        console.log(
            "Adding consumer to subscription ID:",
            subscriptionId,
            "on VRF Coordinator at address:",
            vrfCoordinator
        );
        console.log("Raffle contract address:", contractToAddToVrf);
        console.log("CHAIN ID:", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            contractToAddToVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerWithConfig(mostRecentlyDeployed);
    }
}
