'use strict'

import { EC2Client, DescribeInstancesCommand } from '@aws-sdk/client-ec2';
import { ElasticLoadBalancingV2Client, RegisterTargetsCommand } from '@aws-sdk/client-elastic-load-balancing-v2';

// Initialize EC2 client for cross-region querying (eu-west-1)
const ec2Client = new EC2Client({ region: 'eu-west-1' });

// Initialize ELB client in eu-central-1 for target group modifications
const elbClient = new ElasticLoadBalancingV2Client({ region: 'eu-central-1' });

// Target Group ARN (replace with your actual ARN)
const targetGroupArn = process.env.TARGET_GROUP_ARN;
console.log("targetGroupArn: is ", targetGroupArn)


const asgName = process.env.ASG_NAME;
const asgTag = process.env.ASG_TAG;

// Helper function to get running instances with the AutoScalingGroupName tag
const getRunningInstancesByASGName = async (autoScalingGroupName) => {
    console.log("getRunningInstancesByASGName:", autoScalingGroupName)
    try {
        const command = new DescribeInstancesCommand({
            Filters: [
                // {
                //     Name: 'aws:autoscaling:groupName', // Filter by tag name 'Name'
                //     Values: [autoScalingGroupName]
                // },
                {
                    Name: 'instance-state-name', 
                    Values: ['running']
                }
            ]
        });

        const response = await ec2Client.send(command);

        console.log("DescribeInstancesCommand response:",response)

        // Extract the private IPs of the running instances
        const privateIps = response.Reservations.flatMap(reservation =>
            reservation.Instances.map(instance => instance.PrivateIpAddress)
        );

        console.log("privateIps response:", privateIps)

        return privateIps;
    } catch (error) {
        console.error(`Error retrieving instances for ASG ${autoScalingGroupName}: ${error.message}`);
        throw error;
    }
};

// Helper function to register the private IPs with the target group
const registerTargets = async (privateIps) => {
    try {
        const targets = privateIps.map(ip => ({
            Id: ip, // Register private IP address
            Port: 80 // Ensure this is the correct port for your target group
        }));

        console.log("targets:", targets)

        const command = new RegisterTargetsCommand({
            TargetGroupArn: targetGroupArn,
            Targets: targets
        });

        await elbClient.send(command);
        console.info(`Successfully registered the following private IPs to the target group: ${privateIps.join(', ')}`);
    } catch (error) {
        console.error(`Error registering targets to target group: ${error.message}`);
        throw error;
    }
};

// Lambda handler
export const handler = async (event) => {
    console.info(`Event received: ${JSON.stringify(event)}`);

    // Extract the instance ID and Auto Scaling group name from the SNS message (termination event)
    const snsMessage = event.Records[0].Sns.Message;
    const messageObj = JSON.parse(snsMessage);
    const autoScalingGroupName = messageObj.AutoScalingGroupName;

    if (autoScalingGroupName) {
        console.info(`Processing Auto Scaling Group: ${autoScalingGroupName}`);

        try {
            // Get private IP addresses of running instances in the Auto Scaling group
            const privateIps = await getRunningInstancesByASGName(autoScalingGroupName);

            if (privateIps.length > 0) {
                // Register these running instances' private IPs to the target group
                await registerTargets(privateIps);
            } else {
                console.warn(`No running instances found for Auto Scaling group: ${autoScalingGroupName}`);
            }
        } catch (error) {
            console.error(`Error processing termination event for ASG ${autoScalingGroupName}: ${error.message}`);
        }
    } else {
        console.error('No AutoScalingGroupName found in the message.');
    }
};
