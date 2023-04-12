// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabanukiNFT {
    uint256 public constant PLAYER_COUNT = 4;

    struct Player {
        address playerAddress;
        uint256[] hand;
        uint256[] discarded;
        uint256 ranking;
        bool hasEmptyHand;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;
    uint256[] public deck;
    bool public gameStarted = false;

    constructor() {
        for (uint256 i = 1; i <= 52; i++) {
            deck.push(i);
        }
        // Add Joker
        deck.push(53);
    }

    function sayHello() public pure returns (string memory) {
        return "HELLO BABANUKI";
    }

    function getNumberOfPlayers() public view returns (uint) {
        return playerAddresses.length;
    }

    function joinGameBatch(address[] memory playerAddressesBatch) public {
        require(!gameStarted, "Game has already started.");
        require(
            playerAddresses.length + playerAddressesBatch.length <=
                PLAYER_COUNT,
            "Adding too many players."
        );

        for (uint256 i = 0; i < playerAddressesBatch.length; i++) {
            address playerAddress = playerAddressesBatch[i];

            // Check if player has already joined
            bool hasJoined = false;
            for (uint256 j = 0; j < playerAddresses.length; j++) {
                if (playerAddresses[j] == playerAddress) {
                    hasJoined = true;
                    break;
                }
            }
            require(!hasJoined, "Player has already joined.");

            playerAddresses.push(playerAddress);
            players[playerAddress] = Player(
                playerAddress,
                new uint256[](0),
                new uint256[](0),
                0,
                false
            );
        }
    }

    function shuffleAndDeal() private {
        for (uint256 i = 0; i < 1000; i++) {
            uint256 a = uint256(
                keccak256(abi.encodePacked(block.timestamp, i))
            ) % 53;
            uint256 b = uint256(
                keccak256(abi.encodePacked(block.timestamp, i + 1))
            ) % 53;
            (deck[a], deck[b]) = (deck[b], deck[a]);
        }

        for (uint256 i = 0; i < 53; i++) {
            players[playerAddresses[i % 4]].hand.push(deck[i]);
        }
    }

    function discardPairs(address player) private {
        uint256[] storage hand = players[player].hand;
        uint256[] storage discarded = players[player].discarded;
        uint256 handLength = hand.length;

        for (uint256 i = 0; i < handLength; i++) {
            if (hand[i] == 0) {
                continue;
            }
            for (uint256 j = i + 1; j < handLength; j++) {
                if (hand[j] == 0) {
                    continue;
                }
                if (hand[i] % 13 == hand[j] % 13) {
                    discarded.push(hand[i]);
                    discarded.push(hand[j]);
                    hand[i] = 0;
                    hand[j] = 0;
                    break;
                }
            }
        }

        checkEmptyHand(player);
    }

    event GameStarted(
        address indexed player1,
        address indexed player2,
        address indexed player3,
        address player4,
        uint256[] player1Hand,
        uint256[] player2Hand,
        uint256[] player3Hand,
        uint256[] player4Hand
    );

    function startGame() public {
        require(
            playerAddresses.length == PLAYER_COUNT,
            "Not enough players to start the game."
        );
        require(!gameStarted, "Game has already started.");
        gameStarted = true;

        shuffleAndDeal();

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            discardPairs(playerAddresses[i]);
        }

        emit GameStarted(
            playerAddresses[0],
            playerAddresses[1],
            playerAddresses[2],
            playerAddresses[3],
            players[playerAddresses[0]].hand,
            players[playerAddresses[1]].hand,
            players[playerAddresses[2]].hand,
            players[playerAddresses[3]].hand
        );
    }

    function shuffleDeck() internal {
        // Shuffle the deck using the Fisher-Yates algorithm
        for (uint256 i = 52; i > 0; i--) {
            uint256 j = uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % (i + 1);
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }
    }

    function resetGame() public {
        require(gameStarted, "Game has not started yet.");

        gameStarted = false;

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddress = playerAddresses[i];

            // Clear player's hand and discarded pile
            delete players[playerAddress].hand;
            delete players[playerAddress].discarded;

            // Reset player's ranking and empty hand flag
            players[playerAddress].ranking = 0;
            players[playerAddress].hasEmptyHand = false;
        }

        // Shuffle the deck
        shuffleDeck();
    }

    function checkEmptyHand(address player) private {
        uint256 nonZeroCards = 0;
        for (uint256 i = 0; i < players[player].hand.length; i++) {
            if (players[player].hand[i] != 0) {
                nonZeroCards++;
            }
        }
        players[player].hasEmptyHand = nonZeroCards == 0;
    }

    // function checkAllPlayersFinished() private view returns (bool) {
    //     uint256 finishedPlayers = 0;
    //     for (uint256 i = 0; i < playerAddresses.length; i++) {
    //         if (players[playerAddresses[i]].hasEmptyHand) {
    //             finishedPlayers += 1;
    //         }
    //     }
    //     return finishedPlayers == PLAYER_COUNT;
    // }
}
