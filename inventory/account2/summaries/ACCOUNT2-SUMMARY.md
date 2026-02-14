# OCI Account 2 Infrastructure Inventory Summary

**Tenancy:** wongkm1alex  
**Tenancy OCID:** ocid1.tenancy.oc1..aaaaaaah32ymofcha4imw4qcyi6mjhygj1qijdzla3s4ieaqg5cdlmdylgj1dzta  
**Home Region:** US West (San Jose) - us-sanjose-1  
**Collection Date:** 2026-02-13 21:30 PST  
**Collected By:** comet-atnp3 (Agent Protocol v1.0.0)  

## Executive Summary

Completed READ-ONLY inventory collection of OCI Account 2 infrastructure. All JSON exports successfully collected via OCI CLI in Cloud Shell. 

### Key Findings:
- **VCN CIDR Deviation**: Account 2 uses 10.0.0.0/16 instead of expected 10.2.0.0/16 per BASELINE.md
- **Compute Instances**: 2 instances detected (both VM.Standard.E2.1.Micro, state: RUNNING)
- **Network**: 1 VCN (vcn01) with standard configuration

## Infrastructure Overview

### Compute Instances
