pipeline {
  agent any

  parameters {
    choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'What to do with the infrastructure')
    booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Skip the manual approval gate (not recommended for prod)')
  }

  triggers { githubPush() }   // needs a GitHub webhook -> http://<jenkins>/github-webhook/

  options {
    timestamps()
    disableConcurrentBuilds()   // never let two builds fight over the same state
    timeout(time: 45, unit: 'MINUTES')
  }

  environment {
    TF_IN_AUTOMATION  = 'true'
    TF_VAR_public_key = credentials('ec2-public-key')   // Secret text credential
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Terraform Init & Validate') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            sh 'terraform init -input=false'
            sh 'terraform fmt -check -recursive'
            sh 'terraform validate'
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            script {
              def destroyFlag = (params.ACTION == 'destroy') ? '-destroy' : ''
              sh "terraform plan ${destroyFlag} -input=false -out=tfplan"
            }
          }
        }
      }
    }

    stage('Approval') {
      when { expression { !params.AUTO_APPROVE } }
      steps {
        input message: "Review the plan above. Proceed with '${params.ACTION}'?", ok: 'Yes, go ahead'
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            sh 'terraform apply -input=false tfplan'
          }
        }
      }
    }

    stage('Generate Ansible Inventory') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            sh '''
              echo "[web]" > ../ansible/inventory.ini
              terraform output -json web_public_ips | jq -r '.[]' >> ../ansible/inventory.ini
              cat ../ansible/inventory.ini
            '''
          }
        }
      }
    }

    stage('Ansible Configure') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
          dir('ansible') {
            sh '''
              ansible-playbook site.yml --private-key "$SSH_KEY" --syntax-check
              ansible-playbook site.yml --private-key "$SSH_KEY" -e build_number=${BUILD_NUMBER}
            '''
          }
        }
      }
    }

    stage('Smoke Test') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            sh '''
              for ip in $(terraform output -json web_public_ips | jq -r '.[]'); do
                echo "Testing http://$ip"
                curl -fsS --retry 5 --retry-delay 5 "http://$ip" | grep -q "Deployed by Jenkins"
              done
            '''
          }
        }
      }
    }
  }

  post {
    success { echo "Pipeline finished: ${params.ACTION} succeeded." }
    failure { echo 'Pipeline failed. Check the stage logs above.' }
    always  { archiveArtifacts artifacts: 'ansible/inventory.ini', allowEmptyArchive: true }
  }
}
