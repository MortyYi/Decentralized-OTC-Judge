pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface judge{

    function dispute(uint tradeid,address benifitaddress,uint16 percentofliquiddamage,uint16 subject, uint accusersEvidence, uint defendentsEvidence,uint lengthOfVotableBlock) external payable returns(bool r);
    function getResult(uint id,address contractAddress) external returns (bool result);
    function getName() external returns(string memory r);
    function getURL() external returns(string memory url);
    function getArbitrationFee() external returns(uint start,uint percert);
}

contract judging{
    struct Case{
        uint id;
        uint blockNumber;
        address contractAddress;
        address benifitaddress;
        uint accusersEvidence;
        uint defendentsEvidence;
        uint16 percentofliquiddamage;
        uint16 subject;
        uint approveNumber;
        uint disapproveNumber;
        address payable[] voterAddressApprove;
        address payable[] voterAddressDisapprove;
        uint approveRaiseVoteDeposit;
        uint approveReduceVoteDeposit;
        uint depositToVote;
        uint reward;
        uint lengthOfVotableBlock;
        rejudge[] rejudgeSponsorApprove;
        rejudge[] rejudgeSponsorDisapprove;
        bool ifSplitedReward;
    }
    
    struct rejudge{
        address rejudgeAddress;
        uint rejudgeReward;
    }
    
    struct WaitingForVotingCase{
        uint id;
        uint reward;
        uint depositToVote;
        address contractAddress;
        address benifitaddress;
        uint accusersEvidence;
        uint defendentsEvidence;
    }
    struct voterInfo{
        bool state;
        uint joinDate;
    }
    
    mapping(address => voterInfo) public allVoter;
    Case[] allCase;
    uint depositToBeAVoter=10;
    uint depositToVote=1;
    uint lowestReward=1;
    
    function dispute(uint id,address benifitaddress,uint16 percentofliquiddamage,uint16 subject,uint accusersEvidence,uint defendentsEvidence,uint lengthOfVotableBlock) public payable returns(bool r){
        require(msg.value>=lowestReward,"the reward is not enough");
        address payable[] memory s=new address payable[](0);
        rejudge memory t=new rejudge[];
        uint length = allCase.length;
        Case memory d;
        for (uint i=0; i<length; i++) {
          d = allCase[length-i-1];
          if(d.id==id&&d.contractAddress==msg.sender && (block.number<(d.blockNumber+d.lengthOfVotableBlock+25) || (block.number>(d.blockNumber+d.lengthOfVotableBlock+25) && d.approveNumber==d.disapproveNumber))){
              revert("this case is judging");
          }
        }
        Case memory tempCase = Case(id,block.number,msg.sender,benifitaddress,accusersEvidence,defendentsEvidence,percentofliquiddamage,subject,0,0,s,s,0,0,depositToVote,msg.value,lengthOfVotableBlock,t,t,false);
        allCase.push(tempCase);
        return true;
    }
    
    function rejudge(uint id,address contractAddress) public payable returns(bool){
        // msg.value better be reward?
        require(msg.value==10,"the rejudge fee is not right.");
        uint length = allCase.length;
        Case memory d;
        for (uint i=0; i<length; i++) {
          d = allCase[length-i-1];
          if(d.id==id && d.contractAddress==contractAddress){
              d.lengthOfVotableBlock=d.lengthOfVotableBlock+100;
              d.reward=d.reward+msg.value;
              if(d.approveNumber>d.disapproveNumber){
                  //if rejudgeSponsorApprove[msg.sender]not defined, rejudgeSponsorApprove=??
                  d.rejudgeSponsorApprove[msg.sender]=d.rejudgeSponsorApprove[msg.sender]+10;
              }else{
                  rejudgeSponsorDisapprove[msg.sender]=rejudgeSponsorDisapprove[msg.sender]+10;
              }
           }
        }
    }
    
    function getResult(uint id) public view returns (bool){
        uint length = allCase.length;
        Case memory d;
        for (uint i=0; i<length; i++) {
          d = allCase[length-i-1];
          if(d.id==id && d.contractAddress==msg.sender){
                  if(block.number<d.blockNumber+d.lengthOfVotableBlock+25){
                      revert("please wait for the voting deadline.");
                  }
                  if(d.approveNumber==d.disapproveNumber){
                      revert("equal approve and disapprove Number ,please wait for more vote.");
                  }
                  if(d.approveNumber>d.disapproveNumber){
                      return true;
                  }
                  if(d.approveNumber>d.disapproveNumber){
                      return false;
                  }
         }
        }
    }
    
    function getAllWaitingForVotingCase(uint linenumber)public view returns (WaitingForVotingCase[] memory ss){
      uint length = allCase.length;
      Case memory d;
      WaitingForVotingCase[] memory s = new WaitingForVotingCase[](linenumber);
      uint x = 0;
      for (uint i=0; i<length &&x<linenumber-1; i++) {
          d = allCase[length-i-1];
          if(block.number<(d.blockNumber+d.lengthOfVotableBlock) || (block.number>(d.blockNumber+d.lengthOfVotableBlock) && d.approveNumber==d.disapproveNumber)){
              s[x].id=d.id;
              s[x].reward=d.reward;
              s[x].depositToVote=d.depositToVote;
              s[x].contractAddress=d.contractAddress;
              s[x].benifitaddress=d.benifitaddress;
              s[x].accusersEvidence=d.accusersEvidence;
              s[x].defendentsEvidence=d.defendentsEvidence;
              x = x+1;
          }
      }
      return s;
    }
    
    function joinInJury() payable public returns (bool result){
        require(msg.value==depositToBeAVoter,"deposit not enough");
        require(allVoter[msg.sender] != true,"you are in jury");
        allVoter[msg.sender].state = true;
        allVoter[msg.sender].joinDate = block.number;
        return true;
    }
    
    function quitFromJury() public returns (bool){
        require(allVoter[msg.sender] == true,"you are not in jury");
        allVoter[msg.sender].state = false;
        msg.sender.transfer(depositToBeAVoter);
        return true;
    }
    
    function vote(uint id,address contractAddress,bool caseAttitude,bool voteDepositFeeAttitude) payable public returns (bool){
        require(allVoter[msg.sender].state==true && block.number>allVoter[msg.sender].joinDate+100 ,"you are not a voter");
        uint length = allCase.length;
        Case memory d;
        for (uint i=0; i<length; i++) {
          d = allCase[length-i-1];
          if(d.id==id && d.contractAddress==contractAddress){
              if(msg.value!=d.depositToVote){
                  revert("wrong deposit");
              }
              
              if(block.number<(d.blockNumber+d.lengthOfVotableBlock)){
                  if(caseAttitude){
                      allCase[length-i-1].approveNumber=allCase[length-i-1].approveNumber+1;
                      allCase[length-i-1].voterAddressApprove.push(msg.sender);
                  }else{
                      allCase[length-i-1].disapproveNumber=allCase[length-i-1].disapproveNumber+1;
                      allCase[length-i-1].voterAddressDisapprove.push(msg.sender);
                   }
              
                  if(voteDepositFeeAttitude){
                      allCase[length-i-1].approveRaiseVoteDeposit = allCase[length-i-1].approveRaiseVoteDeposit + 1;
                      return true;
                  }else{
                      allCase[length-i-1].approveReduceVoteDeposit = allCase[length-i-1].approveReduceVoteDeposit + 1;
                      return true;
                  }
              }
              if(block.number>(d.blockNumber+d.lengthOfVotableBlock) && d.approveNumber==d.disapproveNumber){
                  if(caseAttitude){
                      allCase[length-i-1].approveNumber=allCase[length-i-1].approveNumber+1;
                      allCase[length-i-1].voterAddressApprove.push(msg.sender);
                  }else{
                      allCase[length-i-1].disapproveNumber=allCase[length-i-1].disapproveNumber+1;
                      allCase[length-i-1].voterAddressDisapprove.push(msg.sender);
                   }
                  d.lengthOfVotableBlock=d.lengthOfVotableBlock+10;
                  if(voteDepositFeeAttitude){
                      allCase[length-i-1].approveRaiseVoteDeposit = allCase[length-i-1].approveRaiseVoteDeposit + 1;
                      return true;
                  }else{
                      allCase[length-i-1].approveReduceVoteDeposit = allCase[length-i-1].approveReduceVoteDeposit + 1;
                      return true;
                  }
              }else{
                  revert(" vote for this case is over.");
              }
           }
        }
        return false;
    }
    
    function splitReward(uint id,address contractAddress) public returns (bool){
        uint length = allCase.length;
        Case memory d;
        for (uint i=0; i<length; i++) {
            d = allCase[length-i-1];
            if(d.id==id&&d.contractAddress==contractAddress){
                if(d.ifSplitedReward==false && block.number>(d.blockNumber+d.lengthOfVotableBlock+25)){
                    if(d.approveNumber==d.disapproveNumber){
                        revert("equal approveNumber and disapproveNumber, please wait for more vote.");
                    }
                    if(d.approveNumber>d.disapproveNumber){
                        allCase[length-i-1].ifSplitedReward=true;
                        uint averageReward=(d.voterAddressDisapprove.length*d.depositToVote + d.reward)/d.voterAddressApprove.length;
                        uint length2 = d.voterAddressApprove.length;
                        for(uint j=0; j<length2; j++){
                             d.voterAddressApprove[j].transfer(averageReward);
                             
                        }
                        
                        if(d.approveRaiseVoteDeposit>d.approveReduceVoteDeposit){
                             depositToVote = depositToVote*11/10;
                        }
                        if(d.approveRaiseVoteDeposit<d.approveReduceVoteDeposit){
                             depositToVote = depositToVote*10/11;
                        }
                        return true;
                        
                    }
                    if(d.approveNumber<d.disapproveNumber){
                        allCase[length-i-1].ifSplitedReward=true;
                        uint averageReward=(d.voterAddressApprove.length*d.depositToVote + d.reward)/d.voterAddressDisapprove.length;
                        uint length2 = d.voterAddressDisapprove.length;
                        for(uint j=0; j<length2; j++){
                            d.voterAddressDisapprove[j].transfer(averageReward);
                        }
                        if(d.approveRaiseVoteDeposit>d.approveReduceVoteDeposit){
                             depositToVote = depositToVote*11/10;
                        }
                        if(d.approveRaiseVoteDeposit<d.approveReduceVoteDeposit){
                             depositToVote = depositToVote*10/11;
                        }
                        return true;
                    }
                }
            }
        }
        revert("wrong state or id&contractAddress.");
    }
    
    function getTheVoteFee() public view returns (uint theDepositToVote) {
        return depositToVote;
    }
}    