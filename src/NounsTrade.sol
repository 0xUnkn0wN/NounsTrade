// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./NounsToken.sol";

contract NounsTrade {
    NounsToken private _nounsToken;

    address public owner;
    bool public paused = false;

    // Offer status for tokens
    mapping(uint256 tokenIds => bool) openForOffers;

    // Counter offers
    mapping(uint256 tokenIds => mapping(uint256 tokenId => bool)) private offers;

    constructor(address _nounsTokenAddr) {
        owner = msg.sender;
        _nounsToken = NounsToken(_nounsTokenAddr);
    }

    function setOpenForOfferStatus(uint256 tokenId, bool status) public isPaused {
        if (_nounsToken.ownerOf(tokenId) != msg.sender) revert("only the token owner can set open for offers status");
        openForOffers[tokenId] = status;
    }

    function getOpenForOfferStatus(uint256 tokenId) public view returns (bool) {
        return openForOffers[tokenId];
    }

    function createCounterOffer(uint256 tokenId, uint256 counterOfferTokenId) public isPaused {
        if (_nounsToken.ownerOf(counterOfferTokenId) != msg.sender) {
            revert("only the token owner can create counter offers");
        }
        if (_nounsToken.getApproved(counterOfferTokenId) != address(this)) revert("no approve given");

        offers[tokenId][counterOfferTokenId] = true;
    }

    function acceptOffer(uint256 tokenId, uint256 counterOfferTokenId) public isPaused returns (bool) {
        address ownerToken = _nounsToken.ownerOf(tokenId);
        address ownerCounterToken = _nounsToken.ownerOf(counterOfferTokenId);

        if (!openForOffers[tokenId]) revert("no offer exist for this token");
        if (!offers[tokenId][counterOfferTokenId]) revert("no counter offer exist for this combination");
        if (ownerToken != msg.sender) revert("only the token owner can accept offers");
        if (_nounsToken.getApproved(tokenId) != address(this)) revert("no approve given");
        if (_nounsToken.getApproved(counterOfferTokenId) != address(this)) {
            // counter offer token owner reverted approve
            offers[tokenId][counterOfferTokenId] = false;
            return false;
        }

        openForOffers[tokenId] = false;
        _nounsToken.transferFrom(ownerToken, ownerCounterToken, tokenId);
        _nounsToken.transferFrom(ownerCounterToken, ownerToken, counterOfferTokenId);
        return true;
    }

    function setPauseStatus(bool status) public onlyOwner {
        paused = status;
    }

    function setOwner(address _owner) public onlyOwner {
        if (_owner == address(0)) revert("invalid address");
        owner = _owner;
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        _nounsToken = NounsToken(tokenAddress);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert("only the owner is allowed to do this");
        _;
    }

    modifier isPaused() {
        if (paused) revert("contract is paused");
        _;
    }
}
