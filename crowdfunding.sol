//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
 
contract crowdfunding
{
    mapping(address => uint) public contributors;
    mapping(uint=>address) public addressContributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;
 
    struct Request
    {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;
 
    constructor(uint _target, uint _deadline)
    {
        target=_target;
        deadline=block.timestamp+_deadline; //10sec + 3600sec (60*60)
        minimumContribution = 100 wei;
        manager = msg.sender;
    }
 
    function sendEth() public payable
    {
        require(manager != msg.sender,"Manager cannot contributed");
        require(block.timestamp < deadline, "Deadline has passed.");
        require(msg.value >= minimumContribution, "Minimum Contribution is not met.");
        if (contributors[msg.sender] == 0){noOfContributors++;}
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
 
    function getContractBalance() public view returns(uint){return address(this).balance;}
 
    function refund() public
    {
        require(block.timestamp>deadline && raisedAmount<target, "You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }
 
    modifier OnlyManager(){require(msg.sender==manager, "Only manager can call this function");_;}
 
    function createRequests(string memory _description, address payable _recipient, uint _value) public OnlyManager 
    {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters=0;
    }
 
    function voteRequest(uint _requestNo) public
    {
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false, "You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
 
    function makePayment(uint _requestNo) public OnlyManager
    {
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false, "This request has been completed");
        require(thisRequest.noOfVoters>noOfContributors/2, "Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
    function cancelCrowdFunding() public OnlyManager
    {
        for(uint i = 0; i < noOfContributors; i++)
        {
            if(contributors[addressContributors[i]] > 0)
            {
                address payable user = payable(addressContributors[i]);
                user.transfer(contributors[addressContributors[i]]);
                raisedAmount -= contributors[addressContributors[i]];
                contributors[addressContributors[i]] = 0;
            }
        }
    }
}
