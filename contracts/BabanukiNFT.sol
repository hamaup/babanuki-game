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
    bool public gameOverFlag = false;
    uint256 rankingCounter = 1;

    constructor() {
        for (uint256 suit = 1; suit <= 4; suit++) {
            for (uint256 rank = 1; rank <= 13; rank++) {
                deck.push(suit * 100 + rank);
            }
        }
        // Add Joker
        deck.push(999);
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

        for (uint256 i = 0; i < hand.length; i++) {
            if (hand[i] == 0) {
                continue;
            }
            for (uint256 j = i + 1; j < hand.length; j++) {
                if (hand[j] == 0) {
                    continue;
                }
                if (hand[i] % 100 == hand[j] % 100) {
                    // Comparing ranks
                    discarded.push(hand[i]);
                    discarded.push(hand[j]);
                    hand[i] = 0; // Remove card from hand
                    hand[j] = 0; // Remove card from hand
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

        rankingCounter = 1;

        // Shuffle the deck
        shuffleDeck();
    }

    event PlayerFinished(
        address indexed playerAddress,
        bool hasEmptyHand,
        uint256 ranking
    );
    event GameOver(
        bool GameOverFlag,
        address indexed player1,
        address indexed player2,
        address indexed player3,
        address player4,
        uint256 player1Ranking,
        uint256 player2Ranking,
        uint256 player3Ranking,
        uint256 player4Ranking
    );

    function checkEmptyHand(address player) private {
        uint256 nonZeroCards = 0;
        for (uint256 i = 0; i < players[player].hand.length; i++) {
            if (players[player].hand[i] != 0) {
                nonZeroCards++;
            }
        }
        if (nonZeroCards == 0 && players[player].hasEmptyHand == false) {
            players[player].hasEmptyHand = true;
            players[player].ranking = rankingCounter;
            rankingCounter++;
        }
    }

    function checkAllPlayersFinished() private returns (bool) {
        uint256 emptyHandPlayers = 0;
        address lastPlayer;

        // 手札が空のプレイヤーを探す
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            if (players[playerAddresses[i]].hasEmptyHand) {
                emptyHandPlayers++;
            } else {
                lastPlayer = playerAddresses[i];
            }
        }

        // 最後に手札を持っていたプレイヤーのランキングを最下位にする
        if (emptyHandPlayers == PLAYER_COUNT - 1) {
            players[lastPlayer].ranking = PLAYER_COUNT;
            return true;
        }

        return false;
    }

    event CardDrawn(
        address indexed player1,
        address indexed player2,
        address indexed player3,
        address player4,
        uint256[] player1Hand,
        uint256[] player2Hand,
        uint256[] player3Hand,
        uint256[] player4Hand
    );

    function drawCard(
        uint256 playerIndex,
        uint256 targetPlayerIndex,
        uint256 targetCardIndex
    ) external {
        address player = playerAddresses[playerIndex];
        address targetPlayer = playerAddresses[targetPlayerIndex];
        uint256[] storage targetPlayerHand = players[targetPlayer].hand;

        require(
            targetCardIndex < targetPlayerHand.length,
            "Invalid card index."
        );
        require(
            players[player].hasEmptyHand == false,
            "Player has already finished."
        );
        require(
            players[targetPlayer].hasEmptyHand == false,
            "Target player has already finished."
        );

        uint256 drawnCard = targetPlayerHand[targetCardIndex];
        require(drawnCard != 0, "Card not found in target player's hand.");

        targetPlayerHand[targetCardIndex] = 0; // Mark card as removed in target player's hand
        players[player].hand.push(drawnCard); // Add drawn card to current player's hand

        discardPairs(player);

        checkEmptyHand(player);
        if (players[player].hasEmptyHand) {
            emit PlayerFinished(
                player,
                players[player].hasEmptyHand,
                players[player].ranking
            );
        }

        checkEmptyHand(targetPlayer);
        if (players[targetPlayer].hasEmptyHand) {
            emit PlayerFinished(
                targetPlayer,
                players[targetPlayer].hasEmptyHand,
                players[targetPlayer].ranking
            );
        }

        if (checkAllPlayersFinished()) {
            // Emit the GameOver event
            emit GameOver(
                gameOverFlag,
                playerAddresses[0],
                playerAddresses[1],
                playerAddresses[2],
                playerAddresses[3],
                players[playerAddresses[0]].ranking,
                players[playerAddresses[1]].ranking,
                players[playerAddresses[2]].ranking,
                players[playerAddresses[3]].ranking
            );

            // Reset the game or perform any other desired actions for game over
            resetGame();
        }
        emit CardDrawn(
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
}
