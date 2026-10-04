export interface VerificationResult { passed:boolean; evidence:string[]; violations:string[]; metadata:Record<string,unknown>; }
export interface VerifierContract<A,E,S> { verify(action:A,expectedOutcome:E,observedState:S):VerificationResult; }

export function verifyExactText(
  action:{requestedText:string},
  expected:{text:string},
  observed:{insertedText:string;insertionAcknowledgedByHost:boolean}
):VerificationResult {
  const violations:string[]=[];
  const evidence:string[]=[];
  if(!observed.insertionAcknowledgedByHost) violations.push("host did not independently acknowledge insertion");
  if(observed.insertedText!==expected.text) violations.push("observed text does not equal expected text");
  if(violations.length===0){evidence.push("host acknowledgement matched");evidence.push("observed text matched expected text");}
  return {passed:violations.length===0,evidence,violations,metadata:{actionType:"exact_text_insertion"}};
}
