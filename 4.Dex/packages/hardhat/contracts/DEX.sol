// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this challenge. Also return variable names need to be specified exactly may be referenced (It may be helpful to cross reference with front-end code function calls).
 */
contract DEX {
	/* ========== GLOBAL VARIABLES ========== */

	IERC20 token; //instantiates the imported contract

	uint256 public totalLiquidity;

	mapping (address => uint256) public liquidity;

	/* ========== EVENTS ========== */

	/**
	 * @notice Emitted when ethToToken() swap transacted
	 */
	event EthToTokenSwap(
		address swapper,
		uint256 tokenOutput,
		uint256 ethInput
	);

	/**
	 * @notice Emitted when tokenToEth() swap transacted
	 */
	event TokenToEthSwap(
		address swapper,
		uint256 tokensInput,
		uint256 ethOutput
	);

	/**
	 * @notice Emitted when liquidity provided to DEX and mints LPTs.
	 */
	event LiquidityProvided(
		address liquidityProvider,
		uint256 liquidityMinted,
		uint256 ethInput,
		uint256 tokensInput
	);

	/**
	 * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
	 */
	event LiquidityRemoved(
		address liquidityRemover,
		uint256 liquidityWithdrawn,
		uint256 tokensOutput,
		uint256 ethOutput
	);

	/* ========== CONSTRUCTOR ========== */

	constructor(address tokenAddr) {
		token = IERC20(tokenAddr); //specifies the token address that will hook into the interface and be used through the variable 'token'
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	function init(uint256 tokens) public payable returns (uint256) {
		require(totalLiquidity == 0, "DEX: init - already has liquidity");
		totalLiquidity = address(this).balance;
		liquidity[msg.sender] = totalLiquidity;
		require(token.transferFrom(msg.sender, address(this), tokens));

		return totalLiquidity;
	}

	function price(
		uint256 xInput,
		uint256 xReserves,
		uint256 yReserves
	) public pure returns (uint256 yOutput) {
		uint256 xInputWithFee = xInput * 997;
		uint256 numerator = xInputWithFee * yReserves;
		uint256 denominator = (xReserves * 1000) + xInputWithFee;
		return (numerator / denominator);
	}

	function getLiquidity(address lp) public view returns (uint256) {
		return liquidity[lp];
	}

	function ethToToken() public payable returns (uint256 tokenOutput) {
		require(msg.value > 0, "Amount must be greater than 0");
		uint256 ethReserves  = address(this).balance - msg.value;
		uint256 tokenReserves = token.balanceOf(address(this));
		tokenOutput = price(msg.value, ethReserves, tokenReserves);
		require(token.transfer(msg.sender, tokenOutput), "ethToToken(): Failed swap.");

		emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
		return tokenOutput;
	}

	/**
	 * @notice sends $BAL tokens to DEX in exchange for Ether
	 */
	function tokenToEth(
		uint256 tokenInput
	) public returns (uint256 ethOutput) {

		require(tokenInput > 0, "You have 0 tokens to swap.");
		uint256 tokenReserves = token.balanceOf(address(this));
		ethOutput = price(tokenInput, tokenReserves, address(this).balance);

		require(ethOutput <= address(this).balance, "ethToToken: insufficient ETH balance");

		require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth: failed swap.");
		
		(bool success,) = msg.sender.call{value: ethOutput}("");
		require(success, "ethToToken: failed to send ETH");

		emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
		return ethOutput;
	}

	
	function deposit() public payable returns (uint256 tokensDeposited) {
		require(msg.value > 0, "Can't deposit 0 ETH.");
		uint256 ethReserve = address(this).balance - msg.value;
		uint256 tokenReserve = token.balanceOf(address(this));
		uint256 tokenDeposit = ((msg.value * tokenReserve) / ethReserve) + 1;

		uint256 liquidityMinted = (msg.value * totalLiquidity) / ethReserve;
		liquidity[msg.sender] += liquidityMinted;
		totalLiquidity += liquidityMinted;

		require(token.transferFrom(msg.sender,address(this), tokenDeposit));

		emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);

		return tokenDeposit;
	}

	function withdraw(
		uint256 amount
	) public returns (uint256 ethAmount, uint256 tokenAmount) {

		require(liquidity[msg.sender] >= amount, "Not enough liquidity to withdraw");

		uint256 ethReserves = address(this).balance;

		uint256 tokenReserves = token.balanceOf(address(this));

		uint256 ethAmountWithdrawn = (amount * ethReserves) / totalLiquidity;

		uint256 tokenAmountWithdrawn = (amount * tokenReserves) / totalLiquidity;

		liquidity[msg.sender] = liquidity[msg.sender] - ethAmountWithdrawn;

		totalLiquidity = totalLiquidity - ethAmountWithdrawn;

		(bool sent,) = payable(msg.sender).call{value: ethAmountWithdrawn}("");
		require(sent,"Withdrawal Failed");

		require(token.transfer(msg.sender, tokenAmountWithdrawn));

		emit LiquidityRemoved(msg.sender,amount, tokenAmountWithdrawn, ethAmountWithdrawn);

		return (ethAmountWithdrawn, tokenAmountWithdrawn);
	}
}
