pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./lib/Types.sol";

contract Stream {
    using SafeMath for uint256;

    mapping(uint256 => Types.Stream) internal streams;
    uint256 public nextStreamId;

    constructor() public {
        nextStreamId = 1;
    }

    function createStream(
        address _recipient,
        uint256 _deposit,
        address _tokenAddress,
        uint256 _startTime,
        uint256 _stopTime
    )
        public
        virtual
        payable
        _baseStreamRequirements(_recipient, _deposit, _startTime)
        returns (uint256 streamId)
    {
        require(
            _isNonZeroLengthStream(_startTime, _stopTime),
            "Stream must last a least a second"
        );

        uint256 duration = _stopTime.sub(_startTime);
        uint256 ratePerSecond = _ratePerSecond(_deposit, duration);
        require(ratePerSecond > 0, "Rate per second is under 0");

        uint256 streamId = nextStreamId;
        streams[streamId] = Types.Stream({
            remainingBalance: _deposit,
            deposit: _deposit,
            ratePerSecond: ratePerSecond,
            recipient: _recipient,
            sender: msg.sender,
            startTime: _startTime,
            stopTime: _stopTime,
            tokenAddress: _tokenAddress,
            isEntity: true,
            streamType: Types.StreamType.FixedTimeStream
        });

        return streamId;
    }

    modifier _baseStreamRequirements(
        address _recipient,
        uint256 _deposit,
        uint256 _startTime
    ) {
        require(
            _recipient != address(0x00),
            "Cannot start a stream to the 0x address"
        );
        require(
            _recipient != address(this),
            "Cannot start a stream to the stream contract"
        );
        require(_recipient != msg.sender, "Cannot start a stream to yourself");
        require(_deposit > 0, "Cannot start a stream with 0 balance");
        require(
            _startTime >= block.timestamp,
            "Cannot start a stream in the past"
        );
        _;
    }

    modifier _streamExists(uint256 _streamId) {
        require(streams[_streamId].isEntity, "Stream does not exist");
        _;
    }

    function _ratePerSecond(uint256 _deposit, uint256 _duration)
        internal
        virtual
        view
        returns (uint256)
    {
        return _deposit.div(_duration);
    }

    function getStream(uint256 streamId)
        external
        view
        _streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
    }

    function _isNonZeroLengthStream(uint256 _startTime, uint256 _stopTime)
        internal
        view
        returns (bool)
    {
        return _stopTime.sub(_startTime) > 0;
    }
}