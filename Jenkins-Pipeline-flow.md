#Let me explain the key stages in this flow:

**1. Initial Stages:**
- Pipeline starts with parameter selection (Environment & Action)
- Checks out code from SCM
- Sets up Terraform environment

**2. Terraform Initialization:**
- Initializes Terraform
- Selects or creates workspace based on environment
- Performs format check and validation

**3. Action Flow:**
- If Action = 'Apply':
  - For production, requires manual approval
  - Executes Terraform apply

- If Action = 'Destroy':
  - For production, requires manual approval
  - Executes Terraform destroy

**4. Post Actions:**
- Cleans workspace
- Sends success/failure notifications


**This flowchart helps visualize:**
- Decision points in the pipeline
- Security measures (approval steps)
- Different paths based on environment
- Complete pipeline lifecycle
---
```mermaid
flowchart TD
    A[Start Pipeline] --> B[Parameter Selection]
    B --> |Environment & Action| C[Checkout SCM]
    
    C --> D[Setup Terraform]
    D --> E[Terraform Init]
    
    E --> F[Select/Create Workspace]
    F --> G[Terraform Format Check]
    G --> H[Terraform Validate]
    H --> I[Terraform Plan]
    
    I --> J{Action = Apply?}
    J --> |No| M{Action = Destroy?}
    J --> |Yes| K{Is Production?}
    
    K --> |Yes| L[Manual Approval]
    K --> |No| N[Terraform Apply]
    L --> N
    
    M --> |Yes| O{Is Production?}
    M --> |No| P[End Pipeline]
    
    O --> |Yes| Q[Manual Approval]
    O --> |No| R[Terraform Destroy]
    Q --> R
    
    N --> P
    R --> P
    
    subgraph "Post Actions"
    P --> S[Clean Workspace]
    S --> T{Success?}
    T --> |Yes| U[Success Notification]
    T --> |No| V[Failure Notification]
    end
```
