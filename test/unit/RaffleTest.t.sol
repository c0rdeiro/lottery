//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    Raffle private raffle;
    HelperConfig private helperConfig;

    address private PLAYER = makeAddr("PLAYER");
    uint256 private PLAYER_STARTING_BALANCE = 10 ether;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    uint256 entranceFee;
    uint256 interval;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        entranceFee = config.entranceFee;
        interval = config.interval;

        vm.deal(PLAYER, PLAYER_STARTING_BALANCE);
    }

    function testRaffleInitializesInOpenState() external view {
        assert(Raffle.RaffleState.OPEN == raffle.getRaffleState());
    }

    /////////////// ENTER RAFFLE TESTS ///////////////
    function testRaffleRevertsIfNotEnoughEntranceFee() external {
        vm.startPrank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle{value: entranceFee - 1}();
        vm.stopPrank();
    }

    function testRaffleRecordsPlayersOnEntry() external {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        assertEq(raffle.getPlayer(0), PLAYER);
        vm.stopPrank();
    }

    function testEnterRaffleEmitsEvent() external {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    function testDontAllowEntranceWhenRaffleNotOpen() external {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    /////////////// CHECK UPKEEP TESTS ///////////////

    function testCheckUpkeepReturnsFalseIfNoBalance() external {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotOpen() external {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
        vm.stopPrank();
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimePassed() external {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
        vm.stopPrank();
    }

    function testCheckUpkeepReturnsTrueIfConditionsMet() external {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
        vm.stopPrank();
    }

    /////////////// PERFORM UPKEEP TESTS ///////////////

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepCanOnlyBeCalledIfCheckUpkeepReturnsTrue()
        external
        raffleEntered
    {
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepReturnsFalse() external {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState raffleState = Raffle.RaffleState.OPEN;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function testsPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        external
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assert(Raffle.RaffleState.CALCULATING == raffle.getRaffleState());
        assert(uint256(requestId) > 0);
    }

    /////////////// FULFILL RANDOM WORDS TESTS ///////////////
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntered skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }
}
