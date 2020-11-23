/***
* FreeTON Timer contract
* @author: Alexander Miskyakov aka piratealexander
* @license: Apache-2.0
* Contact me with Telegram: @estonianavocado
*/

pragma solidity >= 0.6.0;

pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

abstract contract IContractCall {
    function call() external virtual;
}

contract TimerContract {
   
    uint256 _owner;
    mapping(uint256 => address) savedContracts;
    uint256 neededTonGrams;

   
    uint8 constant ERROR_INVALID_TIME  = 101;
    uint8 constant ERROR_TAKEN         = 102;
    uint8 constant ERROR_INSUFFICIENT_FUNDS      = 103;
    uint8 constant ERROR_INVALID_WAKE  = 104;
    uint8 constant ERROR_INVALID_PUBKEY = 105;

    constructor(uint256 requiredGrams) public {
        tvm.accept();
        _owner = msg.pubkey();
        neededTonGrams = requiredGrams;
    }

    modifier onlyOwner {
        require(msg.pubkey() == _owner, ERROR_INVALID_PUBKEY,"Invalid or empty pubkey");
        tvm.accept();
        _;
    }

    function setRequiredGrams(uint256 reqGrams) public onlyOwner {
        neededTonGrams = reqGrams;
    }

    function checkTime(uint256 time) public returns(bool) {
        tvm.accept();
        return (savedContracts[time] == address.makeAddrNone());
    }

    /**
    * Contract waking request
    */
    function requestToWake(uint256 time, address contractToWake) external returns(bool) {

	//We do some fancy requires here

	//Invalid time
        require(time > now, ERROR_INVALID_TIME);

        //Check for already taken
	require(savedContracts[time] == address.makeAddrNone(), ERROR_TAKEN,"Contract running mutex error");
        
	//Insuffisent funds
        require(msg.value >= neededTonGrams, ERROR_INSUFFICIENT_FUNDS,"INSUFFICIENT FUNDS");
        
	tvm.accept();
        savedContracts[time] = contractToWake;
        return true;
    }

   /**
   * External TickTock Event
   */
    onTickTock(bool isTock) external {
        
	//Running threshold
        optional(uint256, address) minThresholdTime = savedContracts.min();
        

        while(minThresholdTime.hasValue()) {
            

            (uint256 time, address cont) = minThresholdTime.get();
            require(time >= now, ERROR_INVALID_WAKE, "Invalid waking time");
            
	    tvm.accept();
           
	    //Run external contract
            IContractCall(cont).call();
          
            savedContracts.delMin();

            minThresholdTime = savedContracts.min();
        }
    }
}
