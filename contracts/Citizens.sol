// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Citizens is ERC721Votes {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Citizen {
        string name;
        uint roundsSurvived;
        bool exiled;
    }

    Citizen[] public citizens;

    event CitizenNaturalized(uint tokenId, string name);

    bool _gameStarted = false;

    constructor() ERC721("Citizens", "CTZN") EIP712("SurvivorDAO", "1.0.0")  {}

    function mintNFT(string memory _name)
        public
        returns (uint256)
    {
        require(balanceOf(_msgSender()) == 0, "User already owns a token");
        require(!gameStarted(), "Game has already started");
        _tokenIds.increment();

        Citizen memory newCitizen = Citizen(_name, 0, false);
        citizens.push(newCitizen);
        uint256 newItemId = _tokenIds.current();
        _mint(_msgSender(), newItemId);

        emit CitizenNaturalized(newItemId, _name);

        return newItemId;
    }

    function delegate(address delegatee) public virtual override {
        require(delegatee != _msgSender(), "Cannot self-delegate");
        address account = _msgSender();
        _delegate(account, delegatee);
    }

    function startGame() external {
        _gameStarted = true;
    }

    function gameStarted() public view returns (bool) {
        return _gameStarted;
    }

    function getCitizen(uint tokenId) public view returns (Citizen memory) {
        return citizens[tokenId-1];
    }

    function maxActiveVoters() public view returns (uint) {
        return _activeCitizens();
    }

    function _activeCitizens() private view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < citizens.length; i++) {
            if (!citizens[i].exiled) {
                total++;
            }
        }
        return total;
    }

    function _getVotingUnits(address account) internal virtual override returns (uint256) {
        uint accountBalance = balanceOf(account);
        require(accountBalance < 2, "Account seems to have more than one Citizen, invalid state");

        if (accountBalance == 0) {
            return accountBalance;
        }

        uint tokenId = _getTokenIdFromOwner(account);
        if (!citizens[tokenId-1].exiled) {
            return 1;
        } else {
            return 0;
        }
    }

    function _getTokenIdFromOwner(address account) private returns (uint256) {
        require(balanceOf(account) > 1, "address does not own a token");
        for (uint i = 0; i < citizens.length; i++) {
            uint tokenId = i + 1;
            if (_msgSender() == ownerOf(tokenId)) {
                return tokenId;
            }
        }
        revert("Address has a balance greater than 0 but does not map to a token");
    }
}