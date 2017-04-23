    pragma solidity ^0.4.6;
    
    //Contract token is found in its own file. 
    //These here are interfaces to access functions and variable of token contract.      
    contract token { 

                // balance of tokens for individual member
                mapping (address => uint256) public balanceOf;  


                // this function creates new tokens and assigns it to the purchaser.
                // It can be only called by the owner of itself or from functions
                // in this contract which is registered with MyToken contract. 
                                      
                function mintToken (address target, uint256 mintedAmount);
    }

    // @notice a contract which is inherited by 
    // main Associatoion contract. owned holds several houskeeping functions 
    contract owned {
        address public owner;

        
        /// @notice constructor, sets the owner of the contract
        function owned() {
            owner = msg.sender;
        }

        /// @notice modifier to be used in functions, which can be only called 
        /// by the owner, otherwise call to function will be thrown. 
        modifier onlyOwner {
            if (msg.sender != owner) throw;
            _;
        }

        /// @notice used to transfer Ownership
        /// @param newOwner  - new owner of the contract
        function transferOwnership(address newOwner) onlyOwner {
            owner = newOwner;
            
        }	
        
        /// @dev this function will allow on selfdestruction of this contract. 
        function kill() {
            if (msg.sender == owner) selfdestruct(owner);
        }
    }


    /// @dev Liquid Democracy contract. Allows new members to be registered and 
    /// aquire tokens. Number of aquired tokens also represents user voting power. 
    /// Tokens are held in standard token contract defined here. 
    contract ld is owned {

        // How long debate should be held in minutes    
        uint public debatingPeriodInMinutes;
        // proposals array 
        Proposal[] public proposals;
        // to keep number of proposals for easy access
        uint public numProposals;
        // to keep numbrer of members for easy access 
        uint public numMembers;
        // to retrieve a member position in the array without searching for it
        mapping (address => uint) public memberId;   
        // to keep vote weight of each member
        mapping (address => uint256) public voteWeight;
        // keeps delegated votes for each member 
        DelegatedVote[] public delegatedVotes;
        // list of registerd members
        Member[] public members;
        // address of token contract
        token public sharesTokenAddress;
        // total number of tokens in circulation 
        uint public tokensInCirculation;
        // cost of token in wei
        uint public singleTokenCost;
        // date of tokens sale start date in Uinx timestamp
        uint public tokenSaleStartDate;
        // date of tokens sale end date in Unix timestamp
        uint public tokenSaleEndDate;
    
        
    
        // to store member info
        struct Member {
            // the address of member
            address member;
            // true if member can vote
            bool canVote;
            // date member created  
            uint memberSince;
            // first name of member
            string firstName;
            // last name of member 
            string lastName;
            // email address of member
            string userID;
            // true if user has delegated their vote
            bool delegated; 
            // for verification when logging in
            // email address hashed with password    f
            bytes32 memberHash;
            // true if user is admin
            bool admin;  
            // if provided rferral address is stored
            address referral; 
        }
        
        // to store votes delegated by user to another user
        struct DelegatedVote {
            // address of the nominee
            address nominee;
            // address of the voter
            address voter;
            // amount of vote credits, each token is 1 credit 
            uint weight;
        }


        // triggered when new proposal is added
        event ProposalAdded(uint proposalID, address recipient, uint amount, string description, string title);
        // triggered when vote is cast
        event Voted(uint proposalID, bool position, address voter);
        // triggered when votes on proposals are tallied
        event ProposalTallied(uint proposalID, uint yea , uint nay, uint quorum, uint executed);
        // triggered when rules for voting are changed		
        event ChangeOfRules(uint minimumQuorum, uint debatingPeriodInMinutes);
        // triggered when new member is created or updated
        event MembershipChanged(address member, bool isMember, string firstName, string lastName, string userID, address memberReferral);
        // triggered when votes are deleated by a mebmber
        event Delegated(address nominatedAddress, address voters, uint voteIndex);
        // triggered when delegations are reset by admim
        event DelegationReset(bool status);
        // triggered when 
        event DelegationExecuted(bool result);
        event BuyTokens(uint numOfTokens, address buyer, uint value); 
        event BlockUnblockMember(address member, bool status);
        event OwnershipTransfer(bool result);
        event CancelDelegation(address  nominatedAddress, address voter, uint voteWeight);
        event VoteWeightUpdated(address member, uint weightAdded, uint totalWeight);
        event TokenParmsChange(uint startDate, uint endDate, uint tokenPrice);
        
        /* modifier that allows only shareholders to participate in auction */
        modifier onlyShareholders() {
            if (sharesTokenAddress.balanceOf(msg.sender) == 0) throw;
                _;
        }
        
        
        struct Proposal {
            address recipient;
            uint amount;
            string description;
            string title;
            address creator;
            uint votingDeadline;
            uint executed;
            uint numberOfVotes;    
            bytes32 proposalHash;
            Vote[] votes;
            mapping (address => bool) voted;
            string proposalStats;
            
        }

        struct Vote {
            bool inSupport;
            address voter;
        }




    

        /* First time setup */
        function Association(uint minimumSharesToPassAVote, uint minutesForDebate,  token sharesAddress, uint tokenCost) {
            changeVotingRules(minimumSharesToPassAVote, minutesForDebate);        
            sharesTokenAddress = sharesAddress;
            singleTokenCost =  tokenCost;
            tokenSaleStartDate = now;
            tokenSaleEndDate = now + 30 days;

        }

        /*change rules*/
        function changeVotingRules( uint minimumSharesToPassAVote, uint minutesForDebate) onlyOwner {
            
            if (minimumSharesToPassAVote == 0 ) minimumSharesToPassAVote = 1;
            minimumQuorum = minimumSharesToPassAVote;
            debatingPeriodInMinutes = minutesForDebate;           
            
            ChangeOfRules(minimumQuorum, debatingPeriodInMinutes);
        }

        /* Function to create a new proposal */
        function newProposal(
            address beneficiary,
            uint etherAmount,
            string proposalDescription,
            string proposalTitle,
            bytes transactionBytecode
        )
            onlyShareholders()
            returns (uint proposalID)
        {   
        
            proposalID = proposals.length++;
            Proposal p = proposals[proposalID];
            p.recipient = beneficiary;
            p.amount = etherAmount;
            p.description = proposalDescription;
            p.title = proposalTitle;
            p.proposalHash = sha3(beneficiary, etherAmount, transactionBytecode);
            p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
            p.executed = 0;
            p.numberOfVotes = 0;          
            p.creator = msg.sender;
            
            
            numProposals = proposalID+1;

        ProposalAdded(proposalID, beneficiary, etherAmount, proposalDescription, proposalTitle);
        }

        /* function to check if a proposal code matches */
        function checkProposalCode(
            uint proposalNumber,
            address beneficiary,
            uint etherAmount,
            bytes transactionBytecode
        )
            constant
            returns (bool codeChecksOut)
        {
            Proposal p = proposals[proposalNumber];
            return p.proposalHash == sha3(beneficiary, etherAmount, transactionBytecode);
        }


        function changeTokenParms(uint start, uint end, uint tokenPrice){

    
            if (start != 0)   tokenSaleStartDate = start;
            if (end !=0)  tokenSaleEndDate = end;
            if (tokenPrice !=0)  singleTokenCost =tokenPrice ;
            TokenParmsChange(start, end, tokenPrice);

        }

        function transferOwnership(address newOwner) onlyOwner {
        
            // update member records
            members[memberId[newOwner]].admin = true;
            members[memberId[msg.sender]].admin = false;
            
            // call base contract 
            owned.transferOwnership(newOwner);
            OwnershipTransfer(true);
        }	

        /* */
        function vote(uint proposalNumber, bool supportsProposal)
        
        
            onlyShareholders()
            returns (uint voteID)
        {
            Proposal p = proposals[proposalNumber];
            if (p.voted[msg.sender] == true ||  p.executed > 0) throw;

            voteID = p.votes.length++;
            p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
            p.voted[msg.sender] = true;
            p.numberOfVotes = voteID +1;
            Voted(proposalNumber,  supportsProposal, msg.sender);
        }
        
        
        function hasVoted(uint proposalNumber, address voter) constant returns (bool){
            
            Proposal p = proposals[proposalNumber];
            return  p.voted[voter] ;
        }


    function numOfVotes(uint proposalNumber) constant returns (uint){
        
        Proposal p = proposals[proposalNumber];
        return p.votes.length;
        
    }
            
                    
        function howVoted(uint proposalNumber, address voter) constant returns (bool){
            
            Proposal p = proposals[proposalNumber];
            
            for (uint i = 0; i <  p.votes.length; ++i) {
                Vote v = p.votes[i];
                
                if (v.voter == voter) return v.inSupport;
                
            }

            
        }
        
        function hasDelegateVoted(uint proposalNumber, address voter) constant returns (bool){
            
            for (uint i = 0; i < delegatedVotes.length; i++){
                if (delegatedVotes[i].voter== voter){
                    uint id = memberId[delegatedVotes[i].nominee];
                    Member m = members[id];
                    if (m.delegated){
                        hasDelegateVoted(proposalNumber, delegatedVotes[i].nominee);
                    }
                    else {
                            return  hasVoted(proposalNumber, delegatedVotes[i].nominee );
                    }
                }
            }
        }
        
        function howDelegateVoted(uint proposalNumber, address voter) constant returns (bool){
            for (uint i = 0; i < delegatedVotes.length; i++){
                if (delegatedVotes[i].voter== voter){
                    uint id = memberId[delegatedVotes[i].nominee];
                    Member m = members[id];
                    if (m.delegated){
                        howDelegateVoted(proposalNumber, delegatedVotes[i].nominee);
                    }
                    else{
                            return  howVoted(proposalNumber, delegatedVotes[i].nominee );
                    }
                }
            }
            
        }

        
        function calculateVotes(uint proposalNumber) constant returns (string){
            
        
        uint quorum = 0;
        uint votes = 0;
        uint yea = 0;
        uint nay = 0;
        uint totalMemberCount = members.length;
        
        Proposal p = proposals[proposalNumber];

            for (uint i = 0; i <  p.votes.length; ++i) {
                Vote v = p.votes[i];
                uint voteWeightTmp = voteWeight[v.voter];
                
                votes += voteWeightTmp ;
                if (v.inSupport) {
                    yea += voteWeightTmp ;
                } else {
                    nay += voteWeightTmp ;
                }
            }

            quorum = votes * 100/ tokensInCirculation;
        
        string memory tempString = strConcat( "{'yea':", uintToString(yea), ", 'nay':", uintToString(nay));
                tempString = strConcat( tempString, ", 'quorum':", uintToString(quorum), ", 'votes':");
                tempString = strConcat( tempString, uintToString(votes), "}", "");
            
            return tempString;
        }
        

        function executeProposal(uint proposalNumber, bytes transactionBytecode) returns (uint256 result) {
            Proposal p = proposals[proposalNumber];
            /* Check if the proposal can be executed */
            
            
            if (now < p.votingDeadline  /* has the voting deadline arrived? */
                ||  p.executed   > 0     /* has it been already executed? */
                ||  p.proposalHash != sha3(p.recipient, p.amount, transactionBytecode)) /* Does the transaction code match the proposal? */
                throw; 

            /* tally the votes */
        uint quorum = 0;
        uint votes = 0;
        uint yea = 0;
        uint nay = 0;
        uint totalMemberCount = members.length;
        

            for (uint i = 0; i <  p.votes.length; ++i) {
                Vote v = p.votes[i];
                uint voteWeightTmp = voteWeight[v.voter];
                
                votes += voteWeightTmp ;
                if (v.inSupport) {
                    yea += voteWeightTmp ;
                } else {
                    nay += voteWeightTmp ;
                }
            }

            quorum = votes * 100/ tokensInCirculation;
        

            /* execute result */
            if (quorum >= minimumQuorum) {
                        
            if (yea > nay ) {
                /* has quorum and was approved */
                p.executed = 1;  
            // if (!p.recipient.call.value(p.amount * 1 ether)(transactionBytecode)) {
                //  throw;
                }
            else {
                p.executed = 2;
                }
            }

                string memory tempString = strConcat( "{'yea':", uintToString(yea), ", 'nay':", uintToString(nay));
                tempString = strConcat( tempString, ", 'quorum':", uintToString(quorum), ", 'votes':");
                tempString = strConcat( tempString, uintToString(votes), "}", "");
                p.proposalStats = tempString; 
            
        // Fire Events
        ProposalTallied(proposalNumber, yea, nay, quorum, p.executed);
        result = p.executed;
        }

        

        function buyTokens(uint numOfTokens) payable returns (bool){
            

            if (now < tokenSaleStartDate || now > tokenSaleEndDate ) throw;

            if (msg.sender.balance == 0) throw;

            uint totalTokenCost = singleTokenCost * numOfTokens;
            uint userBalance = msg.sender.balance ;
            uint maxTokenToBuy = userBalance / singleTokenCost;

            
            
            if ( numOfTokens >= maxTokenToBuy || totalTokenCost > msg.value){               
                    BuyTokens(0, msg.sender, msg.value);               
                    throw; 
                    } 
            
            sharesTokenAddress.mintToken(msg.sender, numOfTokens);
            tokensInCirculation += numOfTokens;
            
            if (!updateVoteWeight( msg.sender, numOfTokens)) throw;
            BuyTokens(numOfTokens, msg.sender, msg.value);

            return true; 
        }




        
        
    
        function updateVoteWeight(address member, uint numTokens) private returns (bool success){

                    voteWeight[member] += numTokens;
                    VoteWeightUpdated(member, numTokens, voteWeight[member]);
                    return true;
            
            return false;
        }

        function removeDelegation(address voter, uint index, bool first) {
            
            uint id;
        // uint weight = 0;
            
        // id = memberId[voter];
        // Member m = members[id];
            //address nominee;


            for (uint i = 0; i < delegatedVotes.length; i++){

                if (delegatedVotes[i].voter== voter){
                    uint idNominee =  memberId[delegatedVotes[i].nominee];
                    Member n = members[idNominee];
                    if (n.delegated){
                        removeDelegation(delegatedVotes[i].nominee, index, false);
                    }
                    else{
                        if (first) index = i;
                        
                        DelegatedVote nv = delegatedVotes[i];           
                        DelegatedVote vv = delegatedVotes[index]; 
                        voteWeight[nv.nominee] -= vv.weight ;									
                        voteWeight[vv.voter] += vv.weight ;
                        id = memberId[vv.voter];
                        Member m = members[id];
                        m.delegated = false;
                        CancelDelegation(nv.nominee, voter, vv.weight);
                        delete delegatedVotes[index];
                    }
                }
            }
            
        }
        
        
        function delegate(address nominatedAddress) returns (uint voteIndex) {
            
            uint id;
                
            uint weight = 0;
            id = memberId[msg.sender];
            Member m = members[id];
            //don't allow members delegation to themselves
            if (nominatedAddress != msg.sender){
                //test if member is not banned
                if (m.canVote){
                    //check if member hasn't delegted theirvote yet
                    if (!m.delegated){
                        
                        weight = voteWeight[msg.sender] ;
                        voteWeight[msg.sender] -= weight;									
                        voteWeight[nominatedAddress] += weight;
                        m.delegated = true;	
                        //mark delegating member as not delgated in case he/she delegated their votes before himself
                        id = memberId[nominatedAddress];
                        Member n = members[id];
                        n.delegated = false;
                        
                        //check if this first delegation and handle resizing of array appropriatly	
                        if (delegatedVotes.length == 1 && delegatedVotes[0].nominee == 0  ){			
                            delegatedVotes[delegatedVotes.length -1] = DelegatedVote({nominee: nominatedAddress, voter: msg.sender, weight:weight});
                        }
                        else {
                            delegatedVotes.length ++;
                            delegatedVotes[delegatedVotes.length -1] = DelegatedVote({nominee: nominatedAddress, voter: msg.sender, weight:weight});
                        }

                    // DelegatedVote v = delegatedVotes[delegatedVotes.length -1];
                    
                    

                        
                    }   
                }
            }
            voteIndex = delegatedVotes.length -1;
            Delegated( nominatedAddress, msg.sender , voteIndex);
        }

        
        
        function resetDelegation() onlyOwner returns (bool result) 
        {
            for (uint i=0; i< members.length; i++) {
                    voteWeight[members[i].member] = sharesTokenAddress.balanceOf(members[i].member);		
                    members[i].delegated= false;
                }		
            delete delegatedVotes;
            DelegationReset(true);
            return true;
        }

        function completeDelegation() returns (bool result) {
            
            uint weight = 0;
            DelegatedVote v = delegatedVotes[0];	
            uint i;
            bool executed;
            executed = false;		
                    
            if (!executed) {                     
                    for (i=0; i< delegatedVotes.length; i++){
                        v = delegatedVotes[i];					
                        if (v.nominee != v.voter && voteWeight[v.voter] > 0) {
                            weight = voteWeight[v.voter] ;
                            voteWeight[v.voter] -= weight;									
                            voteWeight[v.nominee] += weight;	
                executed = true;						
                        }                                   
                }
            }
        DelegationExecuted(executed);
            return executed;
        }
        
        
       
        
        function blockUnblockMember(address targetMember, bool canVote) onlyOwner {
            
            uint id;
            id = memberId[targetMember];
            Member m = members[id];
            m.canVote = canVote;
            BlockUnblockMember(targetMember, canVote);
        }
        
        /*make member*/
        ///Enter user id and password to access this contract over the online app
        function newMember(address targetMember, bool canVote, string firstName, string lastName, string userID,  bytes32 memberHash, uint tokenNum, address memberReferral)  {
            
            
            uint id;
            bool delegated = false;
            bool adminFlag = false;
            
        
            
            if (stringsEqualMemory("admin@admin.com", userID)){adminFlag = true;}
            

            if(getMemberByUserID(userID) >= 0){
                throw;
                

            }
                                
            else if (voteWeight[targetMember]==0) {
            
                memberId[targetMember] = members.length ;
                id = members.length++;
                members[id] = Member({member: targetMember, canVote: canVote, memberSince: now, firstName: firstName, lastName:lastName, userID:userID, delegated:false,  memberHash:memberHash, admin:adminFlag, referral:memberReferral});			
                voteWeight[targetMember]=0;	            
                numMembers++;	

                sharesTokenAddress.mintToken(targetMember, tokenNum);
                tokensInCirculation += tokenNum;            
                updateVoteWeight( targetMember, tokenNum);  
                			
            } 
            MembershipChanged(targetMember, canVote, firstName, lastName, userID, memberReferral);
                     
        }


    function getMemberByUserID(string userID) constant returns (int memberPosition){
        
        if (members.length == 0) {
            return -1;
            }

        for (uint i=0; i < members.length; i++){
                if (stringsEqual(members[i].userID , userID) ){
                return int(i);
                
                }
                
        }       
        return -1;
        
    }
        
        
        function stringsEqualMemory(string memory _a, string memory _b) internal returns (bool) {
            bytes memory a = bytes(_a);
            bytes memory b = bytes(_b);
            if (a.length != b.length)	
                return false;
            // @todo unroll this loop
            for (uint i = 0; i < a.length; i ++)
                if (a[i] != b[i])
                    return false;
            return true;
        }

    function stringsEqual(string storage _a, string memory _b) internal returns (bool) {
            bytes storage a = bytes(_a);
            bytes memory b = bytes(_b);
            if (a.length != b.length)	
                return false;
            // @todo unroll this loop
            for (uint i = 0; i < a.length; i ++)
                if (a[i] != b[i])
                    return false;
            return true;
        }


        


    function strConcat(string _a, string _b, string _c, string _d, string _e) internal constant returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    
    }

    function strConcat(string _a, string _b, string _c, string _d) internal constant returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal constant returns (string) {
        return strConcat(_a, _b, "", "", "");
    }


    


    function uintToString(uint a) internal constant returns (string){
        
        bytes32 st = uintToBytes(a);
        return bytes32ToString(st);
    }

    function uintToBytes(uint v) internal constant returns (bytes32 ret) {
            if (v == 0) {
                ret = '0';
            }
            else {
                while (v > 0) {
                    ret = bytes32(uint(ret) / (2 ** 8));
                    ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                    v /= 10;
                }
            }
            return ret;
        }
        
        
        function bytes32ToString(bytes32 x) internal constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }


    }


