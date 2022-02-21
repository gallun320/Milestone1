//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20WithAuction is IERC20 {
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => mapping(uint => uint)) private _voices;

    uint256 private _totalSupply;
    uint256 private immutable _startAuctionAmount;

    string private _name;
    string private _symbol;

    uint private _currentPrice;
    uint private _endAuction;
    uint private immutable duration;
    
    mapping(uint => uint) _bets;
    mapping(address => uint) _betSetted;
    uint private _greatestBet;
    uint private _auctionPrice;

    address private immutable _owner;
    
    constructor(uint256 _initialAmount, uint _duration) {
        _owner = msg.sender;
        balances[_owner] = _initialAmount;               
        _totalSupply = _initialAmount;   
        _startAuctionAmount = (5 * _totalSupply) / 100;
        name = "TEST";                                   
        decimals = 18;                            
        symbol = "TST"; 
        duration = _duration;                              
    }

    function startVoting() external {
        uint balance = balances[msg.sender];
        require(balance >= _startAuctionAmount);
        require(block.timestamp > _endAuction);
        _endAuction = block.timestamp + duration;
    }

    function vote(uint price) external {
        require(_betSetted[msg.sender] == 0);
        uint balance = balances[msg.sender];
        uint voices = _voices[msg.sender][_endAuction]; 
        if(voices > 0)
        {
            balance = voices;
        }

        _betSetted[msg.sender] = balance;
        uint bet = _bets[price] + balance;
        _bets[price] = bet;
        if(_greatestBet < bet)
        {
            _greatestBet = bet;
            _auctionPrice = price;
        }
    }

    function endVoting() external {
        uint balance = balances[msg.sender];
        require(balance >= _startAuctionAmount);
        require(block.timestamp > _endAuction && _auctionPrice > 0);
        _currentPrice = _auctionPrice;
        _auctionPrice = 0;
    }

    function auctionPrice() external view returns(uint) {
        return _auctionPrice;
    }

    function greatestBet() external view returns(uint) {
        return _greatestBet;
    }

    function currentPrice() external view returns(uint) {
        return _currentPrice;
    }

    function buy(uint amount) external payable {
        require(msg.value == _currentPrice);
        uint balance = balances[_owner];
        require(balance >= amount);
        balances[_owner] = balance - amount;
        uint buyerBalance = balances[msg.sender];
        balances[msg.sender] = buyerBalance + amount;
    }

    function sell(uint amount) external payable {
        uint balance = balances[msg.sender];
        require(balance >= amount);
        uint ownerBalance = balances[_owner];
        balances[_owner] = ownerBalance + amount;
        balances[msg.sender] = balance - amount;
        require(payable(msg.sender).send(_currentPrice));
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value, "token balance is lower than the value requested");

        uint voiceTo = _voices[_to][_endAuction];
        uint voiceFrom = _voices[msg.sender][_endAuction];

        if(voiceTo == 0)
        {
            _voices[_to][_endAuction] = balances[_to];
        }

        if(voiceFrom == 0)
        {
            _voices[msg.sender][_endAuction] = balances[msg.sender];
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value, "token balance or allowance is lower than amount requested");

        uint voiceTo = _voices[_to][_endAuction];
        uint voiceFrom = _voices[_from][_endAuction];

        if(voiceTo == 0)
        {
            _voices[_to][_endAuction] = balances[_to];
        }

        if(voiceFrom == 0)
        {
            _voices[_from][_endAuction] = balances[_from];
        }

        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < 10) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}