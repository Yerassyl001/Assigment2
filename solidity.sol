// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    address public player1;
    address public player2;
    uint256 public betAmount;
    bytes32 public encrMove1;
    bytes32 public encrMove2;
    string public clearMove1;
    string public clearMove2;
    uint256 public revealDeadline;
    uint256 public REVEAL_TIMEOUT = 3600; // Set your reveal timeout in seconds (e.g., 1 hour)

    constructor(uint256 _betAmount) {
        require(_betAmount >= 0.0001 ether, "Minimum bet is 0.0001 ether");
        betAmount = _betAmount;
    }

    function register() external payable {
        require(msg.value == betAmount, "Please send the correct amount of Ether.");
        require(player1 == address(0) || player2 == address(0), "Both players are already registered.");
        if (player1 == address(0)) {
            player1 = msg.sender;
        } else {
            player2 = msg.sender;
            revealDeadline = block.timestamp + REVEAL_TIMEOUT;
        }
    }

    function play(bytes32 _encrMove) external {
        require(msg.sender == player1 || msg.sender == player2, "You are not registered to play.");
        require(keccak256(abi.encodePacked(_encrMove)) != encrMove1 && keccak256(abi.encodePacked(_encrMove)) != encrMove2, "Move already made.");
        if (msg.sender == player1) {
            encrMove1 = _encrMove;
        } else {
            encrMove2 = _encrMove;
        }
    }

    function reveal(string memory _clearMove) external {
        require(msg.sender == player1 || msg.sender == player2, "You are not registered to reveal.");
        require(block.timestamp <= revealDeadline, "Reveal phase has ended.");
        bytes32 hash = keccak256(abi.encodePacked(_clearMove));
        require(hash == encrMove1 || hash == encrMove2, "Invalid move.");
        if (msg.sender == player1) {
            require(bytes(clearMove1).length == 0, "You have already revealed your move.");
            clearMove1 = _clearMove;
        } else {
            require(bytes(clearMove2).length == 0, "You have already revealed your move.");
            clearMove2 = _clearMove;
        }
    }

    function getOutcome() external {
        require(block.timestamp > revealDeadline, "Reveal phase is still ongoing.");
        require(bytes(clearMove1).length > 0 && bytes(clearMove2).length > 0, "Both players must reveal their moves.");
        address winner = determineWinner(clearMove1, clearMove2);
        if (winner != address(0)) {
            payable(winner).transfer(address(this).balance);
        } else {
            payable(player1).transfer(betAmount);
            payable(player2).transfer(betAmount);
        }
        // Reset the game
        player1 = address(0);
        player2 = address(0);
        encrMove1 = bytes32(0);
        encrMove2 = bytes32(0);
        clearMove1 = "";
        clearMove2 = "";
    }

    function determineWinner(string memory move1, string memory move2) internal pure returns (address) {
        if (compareMoves(move1, move2)) {
            return player1;
        } else if (compareMoves(move2, move1)) {
            return player2;
        } else {
            return address(0); // Draw
        }
    }

    function compareMoves(string memory move1, string memory move2) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(move1)) == keccak256("rock") && keccak256(abi.encodePacked(move2)) == keccak256("scissors")) ||
               (keccak256(abi.encodePacked(move1)) == keccak256("scissors") && keccak256(abi.encodePacked(move2)) == keccak256("paper")) ||
               (keccak256(abi.encodePacked(move1)) == keccak256("paper") && keccak256(abi.encodePacked(move2)) == keccak256("rock"));
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function whoAmI() external view returns (uint256) {
        if (msg.sender == player1) {
            return 1;
        } else if (msg.sender == player2) {
            return 2;
        } else {
            return 0;
        }
    }

    function bothPlayed() external view returns (bool) {
        return (encrMove1 != bytes32(0) && encrMove2 != bytes32(0));
    }

    function bothRevealed() external view returns (bool) {
        return (bytes(clearMove1).length > 0 && bytes(clearMove2).length > 0);
    }

    function revealTimeLeft() external view returns (uint256) {
        if (block.timestamp <= revealDeadline) {
            return revealDeadline - block.timestamp;
        } else {
            return 0;
        }
    }
}
