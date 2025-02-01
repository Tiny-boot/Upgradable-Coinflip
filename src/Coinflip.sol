// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//WARNING: NEED TO ADD A DEPENDENCY INTO FORGE
error SeedTooShort();


contract Coinflip is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    string public seed; //copied from the previous contract

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        seed = "It is a good practice to rotate seeds often in gambling";

    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}


    /// @notice Checks user input against contract generated guesses
    /// @param Guesses is a fixed array of 10 elements which holds the user's guesses. The guesses are either 1 or 0 for heads or tails
    /// @return true if user correctly guesses each flip correctly or false otherwise
    function UserInput(uint8[10] calldata Guesses) external view returns(bool){
        uint8[10] memory flips = getFlips();
        for (uint i = 0; i < 10; i++){
            if (Guesses[i] != flips[i]){
                return false;
            }
        }
        return true;
    }

    /// @notice allows the owner of the contract to change the seed to a new one
    /// @param NewSeed is a string which represents the new seed
    function seedRotation(string memory NewSeed) public onlyOwner {
        bytes memory stringInBytes = bytes(NewSeed);
        uint seedlength = stringInBytes.length;
        // Check if the seed is less than 10 characters (This function is given to you)
        if (seedlength < 10){
            revert SeedTooShort();
        }
        
        seed = NewSeed;
    }

// -------------------- helper functions -------------------- //
    /// @notice This function generates 10 random flips by hashing characters of the seed
    /// @return a fixed 10 element array of type uint8 with only 1 or 0 as its elements
function getFlips() public view returns(uint8[10] memory){
    bytes memory stringInBytes = bytes(seed);
    uint seedlength = stringInBytes.length;
    uint8[10] memory elements;
    // Setting the interval for grabbing characters
    uint interval = seedlength / 10;

    for (uint i = 0; i < 10; i++){
        // Generating a pseudo-random number by hashing together the character and the block timestamp
        uint randomNum = uint(keccak256(abi.encode(stringInBytes[i*interval % seedlength], block.timestamp)));
        
        if (randomNum % 2 == 0){
            elements[i] = 1;
        } else {
            elements[i] = 0;
        }
    }

    return elements;
}
}