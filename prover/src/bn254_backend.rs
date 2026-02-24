use ark_bn254::{Bn254, Fr};
use ark_groth16::{Groth16, PreparedVerifyingKey, Proof, ProvingKey, VerifyingKey};
use ark_relations::r1cs::{ConstraintSynthesizer, ConstraintSystemRef, SynthesisError};
use ark_snark::SNARK;
use ark_serialize::{CanonicalDeserialize, CanonicalSerialize};
use rand::rngs::OsRng;

use crate::types::{BackendType, UniversalProof};

#[derive(Clone)]
pub struct MultiplyCircuit {
    pub a: Option<Fr>,
    pub b: Option<Fr>,
}

impl ConstraintSynthesizer<Fr> for MultiplyCircuit {
    fn generate_constraints(self, cs: ConstraintSystemRef<Fr>) -> Result<(), SynthesisError> {
        use ark_r1cs_std::prelude::*;
        use ark_r1cs_std::fields::fp::FpVar;
        
        let a_var = FpVar::new_witness(cs.clone(), || {
            self.a.ok_or(SynthesisError::AssignmentMissing)
        })?;
        
        let b_var = FpVar::new_witness(cs.clone(), || {
            self.b.ok_or(SynthesisError::AssignmentMissing)
        })?;
        
        let c_var = &a_var * &b_var;
        
        c_var.enforce_equal(&FpVar::new_input(cs.clone(), || {
            Ok(self.a.unwrap_or_default() * self.b.unwrap_or_default())
        })?)?;
        
        Ok(())
    }
}

pub struct BN254Backend {
    pub proving_key: Option<ProvingKey<Bn254>>,
    pub verifying_key: Option<VerifyingKey<Bn254>>,
}

impl BN254Backend {
    pub fn new() -> Self {
        Self {
            proving_key: None,
            verifying_key: None,
        }
    }
    
    pub fn setup(&mut self) -> Result<(), String> {
        let mut rng = OsRng;
        let circuit = MultiplyCircuit { a: None, b: None };
        
        let (pk, vk) = Groth16::<Bn254>::circuit_specific_setup(circuit, &mut rng)
            .map_err(|e| format!("Setup failed: {:?}", e))?;
        
        self.proving_key = Some(pk);
        self.verifying_key = Some(vk);
        
        Ok(())
    }
    
    pub fn prove(&self, a: u64, b: u64) -> Result<UniversalProof, String> {
        let pk = self.proving_key.as_ref().ok_or("Setup not performed")?;
       
       //creating the circuit with real values 
       //Fr::from(a) converts u64 to field element
        let mut rng = OsRng;
        
        let circuit = MultiplyCircuit {
            a: Some(Fr::from(a)),
            b: Some(Fr::from(b)),
        };
        
        let proof = Groth16::<Bn254>::prove(pk, circuit, &mut rng)
            .map_err(|e| format!("Proving failed: {:?}", e))?;
        
        // Serialize proof
        let mut proof_bytes = Vec::new();
        proof.serialize_compressed(&mut proof_bytes)
            .map_err(|e| format!("Serialization failed: {:?}", e))?;
        
        // Calculate public output
        let c = a * b;
        
        Ok(UniversalProof {
            backend: BackendType::BN254,
            proof_bytes,
            public_inputs: vec![c.to_string()],
        })
    }
    
    //get verifying key
    pub fn verify(&self, proof: &UniversalProof) -> Result<bool, String> {
        let vk = self.verifying_key.as_ref().ok_or("Setup not performed")?;
        
        //coverts bytes back to proof structure
        let groth_proof: Proof<Bn254> = Proof::deserialize_compressed(&proof.proof_bytes[..])
            .map_err(|e| format!("Deserialization failed: {:?}", e))?;
        
        let public_input: u64 = proof.public_inputs[0].parse()
            .map_err(|_| "Invalid public input")?;
        let public_inputs = vec![Fr::from(public_input)];
        
        //parse the public value 
        let pvk = PreparedVerifyingKey::from(vk.clone());
        
//Pre-compute some values for faster verification 

        let valid = Groth16::<Bn254>::verify_with_processed_vk(&pvk, &public_inputs, &groth_proof)
            .map_err(|e| format!("Verification failed: {:?}", e))?;
        
        Ok(valid)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
//Only compiles this code when running tests
//Mark function as a test case
//Fail test if condition is false

    #[test]
    fn test_bn254_prove_verify() {
        let mut backend = BN254Backend::new();
        backend.setup().expect("Setup should succeed");
        
        let proof = backend.prove(3, 7).expect("Proving should succeed");
        assert_eq!(proof.public_inputs[0], "21");
        
        let valid = backend.verify(&proof).expect("Verification should succeed");
        assert!(valid);
    }
}