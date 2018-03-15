pragma solidity ^0.4.18;
/**
 * @title DockToken Interface
 * @dev Interface to make use of DockToken Contract
 */
contract DockToken {
    function balanceOf(address who) public view returns (uint256);
}   
/**
 * @title IPFS hash handler
 *
 * @dev IPFS multihash handler. Does a small check to validate that a multihash is
 *   correct by validating the digest size byte of the hash. For example, the IPFS
 *   Multihash "QmPtkU87jX1SnyhjAgUwnirmabAmeASQ4wGfwxviJSA4wf" is the base58
 *   encoded form of the following data:
 *
 *     ┌────┬────┬───────────────────────────────────────────────────────────────────┐
 *     │byte│byte│             variable length hash based on digest size             │
 *     ├────┼────┼───────────────────────────────────────────────────────────────────┤
 *     │0x12│0x20│0x1714c8d0fa5dbe9e6c04059ddac50c3860fb0370d67af53f2bd51a4def656526 │
 *     └────┴────┴───────────────────────────────────────────────────────────────────┘
 *       ▲    ▲                                   ▲
 *       │    └───────────┐                       │
 *   hash function    digest size             hash value
 *
 * we still store the data as `bytes` since it is inherently a variable length structure.
 *
 * @dev See multihash format: https://git.io/vbooc
 */
 
contract DependentOnIPFS {
  /**
   * @dev Validate a multihash bytes value
   */
  function isValidIPFSMultihash(bytes _multihashBytes) internal pure returns (bool) {
    require(_multihashBytes.length > 2);
    uint8 _size;
    // There isn't another way to extract only this byte into a uint8
    // solhint-disable no-inline-assembly
    assembly {
      // Seek forward 33 bytes beyond the solidity length value and the hash function byte
      _size := byte(0, mload(add(_multihashBytes, 33)))
    }
    return (_multihashBytes.length == _size + 2);
  }
}
/**
 * @title Voteable poll with associated IPFS data
 *
 * A poll records votes on a variable number of choices. A poll specifies
 * a window during which users can vote. Information like the poll title and
 * the descriptions for each option are stored on IPFS.
 */
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Poll is DependentOnIPFS {
    
  using SafeMath for uint256;  
  // There isn't a way around using time to determine when votes can be cast
  
  bytes public pollDataMultihash;
  uint16 public numChoices;
  uint256 public startTime;
  uint256 public endTime;
  address public author;
  address public votingCenterAdminAddress;
  DockToken dock;
  
  mapping(address => uint16) public options;
  mapping(address => uint256) public numberOfVotes;
  mapping(uint16 => uint256) public totalVotes;
  
  
  event VoteCast(address indexed voter, uint16 indexed choice);
  event VotingClosed(uint256 endTime);
  function Poll(
    bytes _ipfsHash,
    uint16 _numChoices,
    uint256 _startTime,
    uint256 _endTime,
    address _author,
    DockToken _token,
    address _voting
  ) public {
    require(_startTime >= now && _endTime > _startTime);
    require(isValidIPFSMultihash(_ipfsHash));
    
    numChoices = _numChoices; 
    startTime = _startTime;
    endTime = _endTime;
    pollDataMultihash = _ipfsHash;
    author = _author;
    dock = _token;
    votingCenterAdminAddress = _voting;
  }
  /**
   * @dev Cast or change your vote
   * @param _choice The index of the option in the corresponding IPFS document.
   */
  function vote(uint16 _choice) public duringPoll {
   uint256 dockTokens = dock.balanceOf(msg.sender);
   
   require(dockTokens > 0);
   
    // Choices are indexed from 1 since the mapping returns 0 for "no vote cast"
    require(_choice <= numChoices && _choice > 0);
    if (numberOfVotes[msg.sender] > 0) {
        totalVotes[options[msg.sender]] = totalVotes[options[msg.sender]].sub(numberOfVotes[msg.sender]);
    }
    options[msg.sender] = _choice;
    numberOfVotes[msg.sender] = dockTokens;
    totalVotes[_choice] = totalVotes[_choice].add(dockTokens);
    emit VoteCast(msg.sender, _choice);
  }
   /**
   * End voting close the poll
   */
  function endVoting() public onlyAuthorized  {
      endVotingImpl();
  }
  function endVotingImpl() internal {
      endTime = now;
      emit VotingClosed(endTime);
  }
  
  modifier duringPoll {
    require(now >= startTime && now <= endTime);
    _;
  }
  modifier onlyAuthorized {
     require(msg.sender == author || msg.sender == votingCenterAdminAddress);
     _;
  }
}
/*
 * @title Dock voting center
 * @dev The voting center is the home of all polls conducted within the Dock network.
 *   Anyone can create a new poll and there is no "owner" of the network. The Dock dApp
 *   assumes that all polls are in the `polls` field so any Dock poll should be created
 *   through the `createPoll` function.
 */
contract VotingCenter {
  address public votingCenterAdmin;
  Poll[] public polls;
  bool public pollRestricted = true;
  DockToken dock;
  mapping(address => bool) public pollWhitelists;
  event PollCreated(address indexed poll, address indexed author);
  function VotingCenter() public {
    dock = DockToken(0xE5Dada80Aa6477e85d09747f2842f7993D0Df71C);
    votingCenterAdmin = msg.sender;
  }
  
  /*
   * @dev create a poll and store the address of the poll in this contract
   * @param _ipfsHash Multihash for IPFS file containing poll information
   * @param _numOptions Number of choices in this poll
   * @param _startTime Time after which a user can cast a vote in the poll
   * @param _endTime Time after which the poll no longer accepts new votes
   * @return The address of the new Poll
   */
  
  function createPoll(
    bytes _ipfsHash,
    uint16 _numOptions,
    uint256 _startTime,
    uint256 _endTime
  ) public canCreatePoll returns (address)  {
    Poll newPoll = new Poll(_ipfsHash, _numOptions, _startTime, _endTime, msg.sender, dock, votingCenterAdmin);
    polls.push(newPoll);
    emit PollCreated(address(newPoll), msg.sender);
    return address(newPoll);
  }
  function allPolls() view public returns (Poll[]) {
    return polls;
  }
  function numPolls() view public returns (uint256) {
    return polls.length;
  } 
  function addPollWhitelists(address _addr) public onlyVotingCenterAdmin {
    pollWhitelists[_addr] = true;
  }
  
  function addPollWhitelistsBatch(address[] addresses) public onlyVotingCenterAdmin {
    for (uint32 i = 0; i < addresses.length; i++) {
      pollWhitelists[addresses[i]] = true;
    }
  }
  function removePollWhitelists(address _addr) public onlyVotingCenterAdmin {
    pollWhitelists[_addr] = false;
  }
  function deletePoll(uint _index) public onlyVotingCenterAdmin returns(Poll[]) {
    if (_index >= polls.length) return;
    
    for (uint i = _index; i<polls.length-1; i++){
        polls[i] = polls[i+1];
    }
    delete polls[polls.length-1];
    polls.length--;
    return polls;
  }
  function changePollRestriction(bool _status) external onlyVotingCenterAdmin {
    pollRestricted = _status;
  } 
  modifier onlyVotingCenterAdmin {
    require(msg.sender == votingCenterAdmin);
    _;
  }
  modifier canCreatePoll {
    require(dock.balanceOf(msg.sender) > 0);
    require(pollWhitelists[msg.sender] == true || pollRestricted == false);
    _;
  }
}
