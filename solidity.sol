// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RockPaperScissors is Ownable {
    enum Move { None, Rock, Paper, Scissors }

    struct Game {
        address player;
        Move playerMove;
        Move randomMove;
        uint256 amount;
        bool played;
        bool playerWins;
    }

    IERC20 public tBNB;
    uint256 public betAmount = 0.0001 ether;
    uint256 public rewardMultiplier = 2;
    uint256 public gameId = 1;

    mapping(uint256 => Game) public games;
    address[] public players;
    
    event GameCreated(uint256 gameId, address player);
    event GamePlayed(uint256 gameId, address player, Move playerMove, Move randomMove, bool playerWins, uint256 reward);

    constructor(address _tBNB) {
        tBNB = IERC20(_tBNB);
    }

    function createGame() external payable {
        require(msg.value == betAmount, "Please send the correct amount of BNB to play.");
        Game storage game = games[gameId];
        require(!game.played, "The previous game is still ongoing.");
        game.player = msg.sender;
        game.amount = msg.value;
        game.played = false;
        players.push(msg.sender);
        emit GameCreated(gameId, msg.sender);
        gameId++;
    }

    function playGame(Move playerMove, Move randomMove) external {
        require(playerMove >= Move.Rock && playerMove <= Move.Scissors, "Invalid player move.");
        require(randomMove >= Move.Rock && randomMove <= Move.Scissors, "Invalid random move.");

        Game storage game = games[gameId - 1];
        require(!game.played, "Game has already been played.");
        require(msg.sender == game.player, "You are not the player for this game.");

        game.playerMove = playerMove;
        game.randomMove = randomMove;
        game.played = true;

        bool playerWins = isPlayerWinner(playerMove, randomMove);
        game.playerWins = playerWins;

        uint256 reward = playerWins ? game.amount * rewardMultiplier : 0;
        if (reward > 0) {
            payable(msg.sender).transfer(reward);
        }

        emit GamePlayed(gameId - 1, msg.sender, playerMove, randomMove, playerWins, reward);
    }

    function getGameHistory() external view returns (Game[] memory) {
        Game[] memory history = new Game[](gameId - 1);
        for (uint256 i = 1; i < gameId; i++) {
            history[i - 1] = games[i];
        }
        return history;
    }

    function isPlayerWinner(Move playerMove, Move randomMove) internal pure returns (bool) {
        if (playerMove == randomMove) {
            return false; // It's a draw
        }
        if (playerMove == Move.Rock && randomMove == Move.Scissors) {
            return true;
        }
        if (playerMove == Move.Paper && randomMove == Move.Rock) {
            return true;
        }
        if (playerMove == Move.Scissors && randomMove == Move.Paper) {
            return true;
        }
        return false; // Player loses
    }
}
