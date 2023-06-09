// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";  // Make sure you opened VS Code in the root directory of the project if import is giving error
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ContractingPlatform is ERC20 ("ASKS Token", "ASKS" ) {

    // Bidding Struct
    struct Bid {
        string message;
        uint256 amount;
        address bidder;
    }
    
    // Project Structure
    struct Project {
        string title;
        string description;
        uint256 budget;
        bool isOpen;
        uint256[] bidIds;
        mapping(uint256 => Bid) bids;
        address payable creator; 
        uint256 deadline;
        address payable lowestBidder;
        uint256 lowestBid;
        address[] selectedValidators;
    }

    // Party Structure
    struct Party {
        string name;
        bool isValidator;
        uint256 trust_score;
        uint256 balance;
        address partyAddress;
        uint256[] projectIds;
        mapping(uint256 => Project) projects;
    }
    
    mapping (address => Party) public parties;
    address[] public partyAddresses;
    
    uint256 public projectCount;
    
    address public admin;
    
    // SampleToken token = new SampleToken(1150);
       
    constructor() {  
        admin = msg.sender;
        _mint(payable(msg.sender), 5000000000000000000000000000000000000000 * (10 ** 18));
    }


    // Function for creating party
    function createParty(string memory _name, address _partyAddress) public payable {
        require(_partyAddress != admin, "Admin can't be a party");
        // require(msg.sender == admin, "Only admin can create a party");
        require(msg.sender == _partyAddress, "A party with some different address can't be created with your address");
        require(parties[_partyAddress].partyAddress == address(0), "Party already exists");

        Party storage newParty = parties[_partyAddress];
        newParty.name = _name;
        newParty.partyAddress = _partyAddress;
        newParty.projectIds = new uint256[](0);
        newParty.isValidator  = false;
        newParty.balance = 0;

        // Giving 50 token to created party
        uint256 tokenAmount = 50; // Fixed amount of tokens to credit
        // _mint(payable(_partyAddress), tokenAmount * (10 ** 18));
        _transfer(admin, payable(_partyAddress), tokenAmount * (10 ** 18));

        newParty.trust_score = balanceOf(_partyAddress);

        // SampleToken token = new SampleToken(50);

        // token.addToken()
              
        partyAddresses.push(_partyAddress);
    }

    // Function for updating party
    function updateParty(string memory _name, address _partyAddress) public {
        require(parties[_partyAddress].partyAddress != address(0), "Party does not exist");
        // require(msg.sender == admin, "Only admin can update/delete party details.");
        require(msg.sender == parties[_partyAddress].partyAddress, "Only party owner can update/delete party details.");
        Party storage updatedParty = parties[_partyAddress];
        updatedParty.name  = _name;
    }
    
    // Function for deleting a party on platform
    function deleteParty(address _partyAddress) public {
        require(parties[_partyAddress].partyAddress != address(0), "Party does not exist");
        require(msg.sender == parties[_partyAddress].partyAddress, "Only party owner can update/delete party details.");
        delete parties[_partyAddress];
        for (uint256 i = 0; i < partyAddresses.length; i++) {
            if (partyAddresses[i] == msg.sender) {
                partyAddresses[i] = partyAddresses[partyAddresses.length - 1];
                partyAddresses.pop();
                break;
            }
        }
    }

    // Function for creating a project
    function createProject(uint256 _budget, string memory _title, string memory _description, uint256 _deadline) public returns (uint256) {
        require(parties[msg.sender].partyAddress != address(0), "Party does not exist");
        uint256 projectId = projectCount;
        Project storage newProject = parties[msg.sender].projects[projectId];
        newProject.title = _title;
        newProject.description = _description;
        newProject.budget = _budget;
        newProject.isOpen = true;
        newProject.bidIds = new uint256[](0);
        newProject.creator = payable(msg.sender);
        newProject.deadline = _deadline;
        newProject.lowestBidder = payable(address(0));
        newProject.lowestBid = 0;

        parties[msg.sender].projectIds.push(projectId);
        projectCount++;
        return projectId;
    }

    // Function for updating projects
    function updateProject(uint256 _projectId, uint256 _newBudget, string memory _newTitle, string memory _newDescription, uint256 _newDeadline) public {
        Project storage project = parties[msg.sender].projects[_projectId];
        require(project.budget > 0, "Project does not exist");
        require(project.creator == msg.sender, "Only the creator of the project can update it");
        require(project.isOpen, "Project is closed and cannot be updated");
        project.budget = _newBudget;
        project.title = _newTitle;
        project.description = _newDescription;
        // project.isOpen = _isOpen;
        project.deadline = _newDeadline;
    }
    
    // Function for closing projects
    function closeProject(uint256 _projectId) public {
        Project storage project = parties[msg.sender].projects[_projectId];
        require(project.budget > 0, "Project does not exist");
        require(msg.sender == project.creator, "Only the owner can end the project");
        require(block.timestamp >= project.deadline, "Bidding has not yet ended");
        require(project.isOpen, "Project is already closed");
        project.isOpen = false;
    }

    // Function for creating bids on projects
    function createBid(address _partyAddress, uint256 _projectId, string memory _message, uint256 _amount) public{
        Project storage project = parties[_partyAddress].projects[_projectId];
        require(parties[msg.sender].partyAddress != address(0), "Party does not exist");
        require(project.budget > 0, "Project does not exist");
        require(project.isOpen, "Project is not open for bids");
       	require(block.timestamp < project.deadline, "Bidding has ended");
        require(msg.sender != project.creator, "Owner cannot bid on their own project");

        Bid memory newBid = Bid({
            message: _message,
            amount: _amount,
            bidder: msg.sender
        });
        uint256 bidId = project.bidIds.length;
        project.bidIds.push(bidId);
        project.bids[bidId] = newBid;
    }

    // Function for selecting party with minimum bid and returning amounts to all 
    function selectBid(address _partyAddress, uint256 _projectId) public payable {
        Project storage project = parties[_partyAddress].projects[_projectId];
        require(msg.sender == project.creator, "Only project creator can select the winner");
        require(!project.isOpen, "Project must be closed to select a winner");
        require(block.timestamp >= project.deadline, "Bidding has not yet ended");

        uint256 bidCount = project.bidIds.length;

        require(bidCount > 0, "No bids have been placed for this project");
    }

    // For getting bid count on a particular project
    function getBidCount(address _partyAddress, uint256 _projectId) public view returns (uint256) {
	    require(parties[_partyAddress].projects[_projectId].budget > 0, "Project does not exist");
	    return parties[_partyAddress].projects[_projectId].bidIds.length;
	}

    // For getting bid details like message, amount, address of bidders 
    function getBidDetails(address _partyAddress, uint256 _projectId, uint256 _bidId) public view returns (string memory, uint256, address) {
	Project storage project = parties[_partyAddress].projects[_projectId];
	require(project.bids[_bidId].amount > 0, "Bid does not exist");
	return (
		project.bids[_bidId].message,
		project.bids[_bidId].amount,
		project.bids[_bidId].bidder
	);
    }

    // Function for getting details of a particular party
    function getPartyDetails(address _partyAddress) public view returns (string memory, address, uint256, uint256, bool, uint256[] memory){
        Party storage party = parties[_partyAddress];
        require(party.partyAddress != address(0), "Party does not exist");
        return (party.name, party.partyAddress, party.balance, party.trust_score, party.isValidator, party.projectIds);
        // require(parties[_partyAddress].partyAddress != address(0), "Party does not exist");
        // return (parties[_partyAddress].name, parties[_partyAddress].partyAddress, parties[_partyAddress].reputations);
    }

    // Function for getting project counts
    function getProjectCount(address _partyAddress) public view returns (uint256) {
        require(parties[_partyAddress].partyAddress != address(0), "Party does not exist");
        return parties[_partyAddress].projectIds.length;
    }

    // Function for getting all the projects ids associated with a particular party
    function getProjectIds(address _partyAddress) public view returns (uint256[] memory) {
        require(parties[_partyAddress].partyAddress != address(0), "Party does not exist");
        return parties[_partyAddress].projectIds;
    }

    // Function for getting details of a project
    function getProjectDetails(address _partyAddress, uint256 _projectId) public view returns (string memory, string memory, uint256, bool, uint256, address[] memory) {
	require(parties[_partyAddress].projects[_projectId].budget > 0, "Project does not exist");
	return (
	parties[_partyAddress].projects[_projectId].title,
	parties[_partyAddress].projects[_projectId].description,
	parties[_partyAddress].projects[_projectId].budget,
	parties[_partyAddress].projects[_projectId].isOpen,
	parties[_partyAddress].projects[_projectId].deadline,
	parties[_partyAddress].projects[_projectId].selectedValidators
	);
    }

    // Function for getting total no of parties
    function getPartyCount() public view returns (uint256) {
        return partyAddresses.length;
    }
    
    // Function for getting the address of a particular party.
    function getPartyAddress(uint256 index) public view returns (address) {
        return partyAddresses[index];
    }

    // Function random
    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, partyAddresses.length)));
    }
}
