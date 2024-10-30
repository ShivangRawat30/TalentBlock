// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TalentBlock {
    error TalentBlock__PleaseSubmitTwentyPercentOfTotalAmount();
    error TalentBlock__TheJobIsAlreadyTakenOrEnded();
    error TalentBlock__IncorrectValue();

    enum JobStatus {
        None,
        created,
        Started,
        ended,
        cancelled
    }

    struct JobStruct {
        string link;
        JobStatus status;
        address freelancer;
        address owner;
        uint256 amountPayed;
        uint256 totalAmount;
        uint256 endingTime;
    }

    address private owner;
    mapping(address => string) private s_userMetaData;
    mapping(address => mapping(uint256 => JobStruct)) private s_totalJobs;
    mapping(address => uint256) private s_totalJobsMade;
    mapping(address => string) private s_seekerMetaData;
    uint256 constant private PCT = 3;

    event newUserAdded(address indexed owner, string URI);
    event newSeekerAdded(address indexed owner, string URI);
    event JobAdded(address indexed owner, string URI);
    event freelancerAddedToTheJob(address indexed freelancer, uint256 amount);
    event FundedEscrow(address indexed owner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function addUserURI(string memory URI) external {
        s_userMetaData[msg.sender] = URI;
        emit newUserAdded(msg.sender, URI);
    }

    function addSeekerURI(string memory URI) external {
        s_seekerMetaData[msg.sender] = URI;
        emit newSeekerAdded(msg.sender, URI);
    }

    function addJob(string memory URI, uint256 amount, uint256 totalDays) external payable {
        uint256 twentyPercent = getTwentyPercent(amount);
        if (msg.value < twentyPercent) {
            revert TalentBlock__PleaseSubmitTwentyPercentOfTotalAmount();
        }
        s_totalJobsMade[msg.sender]++;
        uint256 jobIndex = s_totalJobsMade[msg.sender];

        s_totalJobs[msg.sender][jobIndex] = JobStruct({
            link: URI,
            status: JobStatus.created,
            freelancer: address(0),
            owner: msg.sender,
            amountPayed: twentyPercent,
            totalAmount: amount,
            endingTime: block.timestamp + (totalDays * 60 * 60 * 24 * 1000)
        });
        emit JobAdded(msg.sender, URI);
    }

    function setFreelancerForJob(uint256 id, address freelancer) external {
        JobStruct memory currJob = s_totalJobs[msg.sender][id];
        if(currJob.status != JobStatus.created){
            revert TalentBlock__TheJobIsAlreadyTakenOrEnded();
        }

        uint256 OwnerAmount = currJob.amountPayed * PCT / 100;
        uint256 freelancerAmount = currJob.amountPayed - OwnerAmount;
        s_totalJobs[msg.sender][id].freelancer = freelancer;
        s_totalJobs[msg.sender][id].status = JobStatus.Started;
        emit freelancerAddedToTheJob(freelancer, currJob.amountPayed);
        _payTo(owner, OwnerAmount);
        _payTo(freelancer, freelancerAmount);
    }

    function cancelJob(uint256 id) external {
        JobStruct memory currJob = s_totalJobs[msg.sender][id];
        if(currJob.status != JobStatus.created){
            revert TalentBlock__TheJobIsAlreadyTakenOrEnded();
        }
        s_totalJobs[msg.sender][id].status = JobStatus.cancelled;
        _payTo(msg.sender, currJob.amountPayed);

    }

    function payAllAmountToEscrow(uint256 id, uint256 amount ) external payable {
        JobStruct memory currJob = s_totalJobs[msg.sender][id];
        if(currJob.status != JobStatus.Started){
            revert TalentBlock__TheJobIsAlreadyTakenOrEnded();
        }
        if(amount != msg.value){
            revert TalentBlock__IncorrectValue();
        }
        uint256 remainingAmount = currJob.totalAmount - currJob.amountPayed;
        if(amount != remainingAmount){
            revert TalentBlock__IncorrectValue();
        }

        emit FundedEscrow(msg.sender, amount);
        
    } 

    function sendMoneyToFreelancer(uint256 id) external {
         JobStruct memory currJob = s_totalJobs[msg.sender][id];

         uint256 remainingAmount = currJob.totalAmount - currJob.amountPayed;
         uint256 ownerAmount = remainingAmount * 3 / 100;
        uint256 transferAmount = remainingAmount - ownerAmount;

        s_totalJobs[msg.sender][id].amountPayed = currJob.totalAmount;
        s_totalJobs[msg.sender][id].status = JobStatus.ended;
        _payTo(owner, ownerAmount);
        _payTo(currJob.freelancer, transferAmount);
    }

    function _payTo(address to, uint256 amount) internal {
        (bool success,) = payable(to).call{ value: amount }("");
        require(success);
    }

    function getTwentyPercent(uint256 totalAmount) public pure returns (uint256) {
        return totalAmount * 20 / 100;
    }

    function getUserURI(address user) external view returns (string memory) {
        return s_userMetaData[user];
    }

    function getSeekerURI(address user) external view returns (string memory) {
        return s_seekerMetaData[user];
    }

    function getJobData(address user, uint256 index) external view returns (JobStruct memory) {
        return s_totalJobs[user][index];
    }

    function getJobStatus(address user, uint256 index) external view returns (JobStatus) {
        return s_totalJobs[user][index].status;
    }

    function getJobFreeLancer(address user, uint256 index) external view returns (address) {
        return s_totalJobs[user][index].freelancer;
    }
}
