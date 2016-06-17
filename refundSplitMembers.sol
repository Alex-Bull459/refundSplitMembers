/*
 * refundSplitMembers.sol - a Solidity Ethereum smartcontract to help theDAO split members recover their ether
 * Copyright (C) 2016 Aeron Buchannan
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */


/* @RefundSplitMembers return theDAO ETH back to split members
 *
 * The priority here is to provide a way for theDAO split members to get their ether out of the contract 
 * without exposing the process to hijacking.
 *
 * The approach of this contract is to be a single recipient for a proposal, so any recursive attack 
 * attempts can't hamper the process.
 *
 * It includes a timelock "cooldown" period in which no funds can be taken out. This period is designed
 * to allow for an appraisal of this contract to check its correctness.
 *
 * It also includes a mechanism for transferring all the ether held by it to a single address if the 
 * members vote to do so, e.g. if an error is found with the refund process.
 *
 * Obviously there is a balance here of providing a secondary payment mechanism as a backup rather than 
 * a backdoor for a malign actor...
 * 
 */

contract refundSplitMembers {
	// number of addresses to be reimbursed, aka members
	int numberMembers = 45; 

	struct MemberDetails
	{
		uint amount;			// amount of wei due for this member
		mapping(uint => bool) votes;	// participation in fallback votes
	}

	// list of addresses to be reimbursed, aka members
	mapping(address => MemberDetails) members; 

	struct FallbackProposal
	{
		address addr;	// address of a fallback option to receive all the eth of this contract
		uint voteCount;	// number of votes for this fallback option
	}

	// list of backup proposals
	FallbackProposal[] fallbackProposals;

	// number of votes required for a proposal to be successful
	uint voteThreshold; 

	// time of refund time-lock release
	uint timelockPeriod; 

	/// Create a new refund contract with hardcoded members for simplicity
	function refundSplitMembers() 
	{
		members["0x..."].amount = ...;
		...

		voteThreshold = ...;
		timelockPeriod = now + 7 days;
	}

	/// The methods of this contract are members only
	modifier membersOnly
	{
		if ( members[msg.sender].amount == 0 ) throw;
		_
	}

	/// If the timelock period is over, allow a member to extract their portion of the funds
	function refund() membersOnly 
	{
		if ( now < timelockPeriod ) throw; // only after time period

		msg.sender.send(members[msg.sender].amount); // send funds owed
		members[msg.sender].amount = 0; // remove from member list
	}

	/// Put forward a single address that can receive all the funds of this contract if enough members vote for it. DANGER!
	function fallbackProposal(address fallback) membersOnly
	{
		fallbackProposals.push(FallbackProposal({
			addr: fallback,
			voteCount: 0
		}));
	}

	/// A member can vote for a fallback address, but only one vote max per address
	function vote(uint proposalNumber) membersOnly
	{
		if ( members[msg.sender].votes[proposalNumber] == true ) throw;

		members[msg.sender].votes[proposalNumber] = true;
		fallbackProposals[proposalNumber].voteCount += 1;
	}

	/// If a fallback address has enough vote, kill this contract and transfer all funds to that address
	function fallback(uint proposalNumber) membersOnly
	{
		if ( fallbackProposals[proposalNumber].voteCount <= voteThreshold ) throw;

		suicide(fallbackProposals[proposalNumber].addr);
	}

}
