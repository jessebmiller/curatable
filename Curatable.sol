pragma solidity ^0.4.4;


import "./zeppelin-solidity/contracts/ownership/Ownable.sol"


contract Curatable is Ownable {

  event PresentationProposed(bytes32);
  event ProposalWithdrawn(bytes32);
  event PresentationCommitted(bytes32);
  event FeePaid(bytes32);
  event NewHandler(address);

  struct Proposal {
    string where;
    string when;
    address promoter;
    uint256 stake;
  }

  struct PresentationCommitment {
    address handler;
    uint256 stake;
  }

  // proposalID => Proposal
  mapping (bytes32 => Proposal) props;
  // proposalID => Committment
  mapping (bytes32 => PresentationCommitment) commitments;
  // proposalID => amount paid
  mapping (bytes32 => uint256) paidFees;

  // promoStakeAmount is the amount that the stakeholders require a promoter to
  // stake in order to promote a presentation
  uint256 promoStakeAmount;

  // handlerStakeAmount is the amount that the stakeholders require a handler to
  // stake in order to commit to a presentation
  uint256 handlerStakeAmount;

  // the handler is responsible to handling the presentable
  // TODO mechanism for stakeholders to change the handler
  address handler;

  // Stakeholders set the fee (in ether?) for presentation
  // TODO mechanism for stakeholders to change the fee
  // TODO mechanism for changing the currency accepted for the fee
  uint256 presentationFee;

  modifier onlyHandler() {
    require(msg.sender == handler);
    _;
  }

  /*
   * Promoters can proposePresentations by giving a location and time that
   * the verifiers will coordinate on when the Schelling Game is run to vefity
   * the presention.
   */
  function proposePresentation(string _where, string _when) public {
    require(balanceOf(msg.sender) >= promoStake);
    balances[msg.sender] -= promoStake;
    propID = keccak256(_where, _when, msg.sender);
    props[propID] = Proposal(_where, _when, msg.sender, promoStakeAmount);
    PresentationProposed(propID);
  }

  /*
   * A promoter can withdraw their proposal until the handler has accepted
   */
  function withdrawProposal(bytes32 _propID) public {
    prop = props[_propID];
    // if this is the promoter
    require(prop.promoter == msg.sender);
    // and the proposal has not been commited to
    require(commitment[_propID] == Proposal("", "", address(0), 0));
    // refund the promoters stake
    balances[msg.sender] += prop.stake;
    // and remove the proposal
    delete props[_propID];
    ProposalWithdrawn(_propID);
  }

  /*
   * The handler (owner) can commit to present a proposal. As they also need to
   * put up a stake, they will want to confirm with the venue that they are
   * indeed willing to accept the proposal before makeing the commitment.
   */
  function commitToPresent(bytes32 _propID) public onlyHandler {
    // if the proposal exists
    require(props[_propID] != Proposal("", "", address(0), 0));
    // and the handler has enough to stake
    require(balanceOf(msg.sender) >= handlerStakeAmount);
    // create the commitment with the stake
    balances[msg.sender] -= handlerStakeAmount;
    commitments[_propID] = PresentationCommitment(msg.sender,
                                                  handlerStakeAmount,
                                                  0);
    PresentationCommitted(_propID);
  }

  /*
   * Anyone can pay the presentation fee.
   * TODO create conditional fee payment structures that let's people commit to
   * help pay for a proposal but refunds the payment if the presentation doesn't
   * happen.
   */
  function payPresentationFee(bytes32 _propID) public payable {
    // as long as there is enough sent
    require(msg.value >= presentationFee);
    // and the fee hasn't already been paid
    require(paidFees[_propID] == 0);
    paidFees[_propID] += msg.value;
    FeePaid(_propID);
  }

  /*
   * when the proposal is accepted, committed to, and paid for, anyone can start
   * the verification phase.
   */
  function startVerification(bytes32 _propID) public {
    require(props[_propID] != Proposal("", "", address(0), 0));
    require(commitments[_propID] != PresentationCommitment(address(0), 0));
    require(paidFees[_propID] > 0);

    // TODO figure out how to run verification
  }
}
