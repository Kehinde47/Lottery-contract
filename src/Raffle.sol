/*
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import {VRFConsumerBaseV2Plus} from "node_modules/@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "node_modules/@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Raffle contract
/// @author Olubunmi-Browns Kehinde
/// @notice The contract is for creating a sample raffle
/// @dev Implement ChainLink VRFv2.5

contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();


//  TYPE DECELRATION
enum RaffleState{
    OPEN,   // INT 0
    CALCULATING // INT 1
}


    // STATE VARAIBLES
    uint256 private immutable i_entranceFee;
    //  @ dev duration of lottery in second
    uint16 private constant REQUEST_CONFIMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    address payable[] private s_players;
    uint256 private immutable i_interval;
    uint256 private immutable i_subcriptionId;
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    address private s_recentWinner;

    RaffleState private s_raffleState;

    // events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_vrfCoordinator.requestRandomWords();
        i_keyHash = gasLane;
        i_subscriptionId = subcriptionId;
        i_callbackGasLimit = callbackGasLimit;
       s_raffleState = RaffleState.OPEN;
       // s_raffleState = RaffleState(0);

    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee , "Not enough room"); // This cost a whole lot of gas as a string
        //require(msg.value >= i_entranceFee , SendMoreToEnterRaffle()); for 0.8.26
        if (msg.value >= i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
        if(s_raffleState != RaffleState){
            revert Raffle__RaffleNotOpen();
        }
    }

    // get a number
    // use random number to pick a player
    // be automatically called

    function pickWinner() external {
        // if enoughtime has passed
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            revert();
        }
                  s_raffleState = RaffleState.CALCULATING;
        // requestId = s_vrfCoordinator.requestRandomWords(
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId, // How to fund the oracle gas
                requestConfirmations: REQUEST_CONFIMATION, // how mant blocs should wait
                callbackGasLimit: callbackGasLimit, // to avoid over spending of gas
                numWords: NUM_WORDS, // how many random numbers
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

// CEI - CHECKS , EFFECTS , INTERCATIONS
    function fufillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal virtual override {
        // CHECKS :  requires , conditionals more gas efficient
        // EFECTS": (INTERNAL CONTRACT STATE) STATE VARAIBLES emits , events  internal variables
   uint256 indexOfWinner = randomWords[0] % s_players.lenght;
   address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;

    
    s_raffleState = RaffleState.OPEN;
      s_players = new address payable[](0);
      s_lastTimeStamp = block.timestamp;
         emit WinnerPicked(s_recentWinner);

    // INTERFACTIONS : EXTERNAL CONTRACTS
    (bool success ,) = recentWinner.call{value:address(this).balance}("");
      if(!success){
        revert Raffle__TransferFailed();
      }
  
    }

    // Getter functions

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
