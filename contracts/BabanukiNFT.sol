// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BabanukiNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bool public gameStarted = false;
    bool public gameOverFlag = false;
    uint8 public constant PLAYER_COUNT = 2;
    uint256 public maxTokenId;
    address winner;
    uint256[] public deck;
    address[] public playerAddresses;
    mapping(address => Player) public players;

    struct Player {
        address playerAddress;
        uint256[] hand;
        uint256[] discarded;
        bool isHuman;
    }

    constructor() ERC721("BBNItem", "BBN") {
        for (uint256 suit = 1; suit <= 4; suit++) {
            for (uint256 rank = 1; rank <= 13; rank++) {
                deck.push(suit * 100 + rank);
            }
        }
        deck.push(999);
    }

    function sayHello() public pure returns (string memory) {
        return "HELLO BABANUKI";
    }

    function getNumberOfPlayers() public view returns (uint) {
        return playerAddresses.length;
    }

    function joinGame() public {
        require(!gameStarted, "Game has already started.");
        require(
            playerAddresses.length + 1 <= PLAYER_COUNT,
            "Adding too many players."
        );

        bool hasJoined = false;
        for (uint256 j = 0; j < playerAddresses.length; j++) {
            if (playerAddresses[j] == msg.sender) {
                hasJoined = true;
                break;
            }
        }
        require(!hasJoined, "Player has already joined.");

        playerAddresses.push(msg.sender);
        players[msg.sender] = Player(
            msg.sender,
            new uint256[](0),
            new uint256[](0),
            true
        );
    }

    function shuffleAndDeal() private {
        for (uint256 i = deck.length; i > 1; i--) {
            uint256 j = uint256(
                keccak256(abi.encodePacked(block.timestamp, i))
            ) % i;
            (deck[i - 1], deck[j]) = (deck[j], deck[i - 1]);
        }

        for (uint256 i = 0; i < 53; i++) {
            players[playerAddresses[i % PLAYER_COUNT]].hand.push(deck[i]);
        }
    }

    function discardPairs(address player) private {
        uint256[] storage hand = players[player].hand;
        uint256[] storage discarded = players[player].discarded;

        uint256 writeIndex = 0;
        for (uint256 i = 0; i < hand.length; i++) {
            if (hand[i] == 0) {
                continue;
            }
            bool isPair = false;
            for (uint256 j = i + 1; j < hand.length; j++) {
                if (hand[j] == 0) {
                    continue;
                }
                if (hand[i] % 100 == hand[j] % 100) {
                    discarded.push(hand[i]);
                    discarded.push(hand[j]);
                    hand[i] = 0;
                    hand[j] = 0;
                    isPair = true;
                    break;
                }
            }
            if (!isPair) {
                hand[writeIndex++] = hand[i];
            }
        }
        while (hand.length > writeIndex) {
            hand.pop();
        }
    }

    function resetGame() public {
        require(gameStarted, "Game has not started yet.");

        gameStarted = false;
        gameOverFlag = false;

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddress = playerAddresses[i];
            delete players[playerAddress].hand;
            delete players[playerAddress].discarded;
        }

        delete playerAddresses;
    }

    event CardDrawn(uint256[] player1Hand, uint256[] player2Hand);
    event GameOver(address winner);

    function drawCard(
        uint8 playerIndex,
        uint8 targetPlayerIndex,
        uint256 targetCardIndex
    ) public {
        address player = playerAddresses[playerIndex];
        address targetPlayer = playerAddresses[targetPlayerIndex];
        uint256[] storage targetPlayerHand = players[targetPlayer].hand;
        require(
            targetCardIndex < players[targetPlayer].hand.length,
            "Invalid card index."
        );

        uint256 drawnCard = players[targetPlayer].hand[targetCardIndex];
        require(drawnCard != 0, "Card not found in target player's hand.");

        players[player].hand.push(drawnCard);
        // Move the last card in the target player's hand to the drawn card's position
        uint256 lastIndex = targetPlayerHand.length - 1;
        targetPlayerHand[targetCardIndex] = targetPlayerHand[lastIndex];

        // Remove the last card from the target player's hand
        targetPlayerHand.pop();

        discardPairs(player);

        bool gameOver = false;

        if (players[player].hand.length == 0) {
            winner = player;
            gameOver = true;
        } else if (players[targetPlayer].hand.length == 0) {
            winner = targetPlayer;
            gameOver = true;
        }

        if (gameOver) {
            emit GameOver(winner);
            resetGame();
        } else {
            emit CardDrawn(
                players[playerAddresses[0]].hand,
                players[playerAddresses[1]].hand
            );
            nextTurn(targetPlayerIndex);
        }
    }

    function chooseRandomCard(
        address targetPlayerAddress
    ) internal returns (uint256) {
        uint256[] storage targetHand = players[targetPlayerAddress].hand;
        require(targetHand.length > 0, "Target player's hand is empty.");
        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.number,
                    targetPlayerAddress
                )
            )
        ) % targetHand.length;

        return randomIndex;
    }

    event NpcTurn(
        uint8 currentPlayerIndex,
        uint8 targetPlayerIndex,
        uint256 chosenCard
    );

    function nextTurn(uint8 currentPlayerIndex) public {
        require(gameStarted, "Game has not started yet.");
        require(!gameOverFlag, "Game is over.");
        uint8 targetPlayerIndex = (currentPlayerIndex + 1) % PLAYER_COUNT;

        if (!players[playerAddresses[currentPlayerIndex]].isHuman) {
            uint256 chosenCard = chooseRandomCard(
                playerAddresses[targetPlayerIndex]
            );
            emit NpcTurn(currentPlayerIndex, targetPlayerIndex, chosenCard);
            drawCard(currentPlayerIndex, targetPlayerIndex, chosenCard);
        }
    }

    event GameStarted(
        address indexed player1,
        address indexed player2,
        uint256[] player1Hand,
        uint256[] player2Hand
    );

    function startGame() public {
        require(
            playerAddresses.length >= 1 &&
                playerAddresses.length <= PLAYER_COUNT,
            "Invalid number of players."
        );
        uint256 playerCount = playerAddresses.length;
        for (uint256 i = playerCount; i < PLAYER_COUNT; i++) {
            // Add NPC player
            address npcAddress = address(
                uint160(
                    uint(
                        keccak256(abi.encodePacked(i, blockhash(block.number)))
                    )
                )
            );
            playerAddresses.push(npcAddress);
            players[npcAddress] = Player(
                npcAddress,
                new uint256[](0),
                new uint256[](0),
                false
            );
        }
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

        winner = address(0);

        emit GameStarted(
            playerAddresses[0],
            playerAddresses[1],
            players[playerAddresses[0]].hand,
            players[playerAddresses[1]].hand
        );
        nextTurn(0);
    }

    event NFTAwarded(
        address indexed recipient,
        uint256 indexed tokenId,
        string tokenURI
    );

    function awardItem(
        address player,
        string memory tokenURI
    ) internal returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();

        if (newItemId > maxTokenId) {
            maxTokenId = newItemId;
        }
        emit NFTAwarded(player, newItemId, tokenURI);
        return newItemId;
    }

    function claimNFT(string memory tokenURI) public {
        require(winner == msg.sender, "Only the winner can claim NFT.");
        awardItem(msg.sender, tokenURI);
        winner = address(0);
    }
}
