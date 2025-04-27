// Lambda function to process DynamoDB Streams
// This demonstrates how to update aggregate counts when new items are added

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb")
const { DynamoDBDocumentClient, UpdateCommand, GetCommand } = require("@aws-sdk/lib-dynamodb")

const client = new DynamoDBClient({})
const docClient = DynamoDBDocumentClient.from(client)

exports.handler = async (event) => {
  console.log("Processing DynamoDB Stream records:", JSON.stringify(event, null, 2))

  try {
    // Process each record in the stream
    for (const record of event.Records) {
      // Only process new items that are inserted
      if (record.eventName === "INSERT") {
        const newItem = record.dynamodb.NewImage

        // Check if this is a new student enrollment
        if (
          newItem.entityType &&
          newItem.entityType.S === "student" &&
          newItem.pk.S.startsWith("course#")
        ) {
          // Extract course ID from the partition key
          const courseId = newItem.pk.S

          // Update the enrollment count for this course
          await updateEnrollmentCount(courseId)
        }

        // Check if this is a submission
        if (newItem.entityType && newItem.entityType.S === "submission") {
          // Update student's grade average
          if (newItem.studentID && newItem.studentID.S) {
            await updateStudentGradeAverage(newItem.studentID.S)
          }
        }
      }
    }

    return { statusCode: 200, body: "Successfully processed DynamoDB Stream events" }
  } catch (error) {
    console.error("Error processing DynamoDB Stream records:", error)
    return { statusCode: 500, body: `Error processing stream records: ${error.message}` }
  }
}

// Function to update the enrollment count for a course
async function updateEnrollmentCount(courseId) {
  try {
    // Get current stats for the course
    const getParams = {
      TableName: process.env.TABLE_NAME,
      Key: {
        pk: courseId,
        sk: "stats",
      },
    }

    let enrollmentCount = 1

    // Try to get existing stats
    try {
      const response = await docClient.send(new GetCommand(getParams))
      if (response.Item && response.Item.enrollmentCount) {
        enrollmentCount = response.Item.enrollmentCount + 1
      }
    } catch (error) {
      // Item doesn't exist yet, we'll create it with count of 1
      console.log("Stats item does not exist yet, will create with count of 1")
    }

    // Update course stats with new enrollment count
    const updateParams = {
      TableName: process.env.TABLE_NAME,
      Key: {
        pk: courseId,
        sk: "stats",
      },
      UpdateExpression: "SET enrollmentCount = :count, entityType = :type, lastUpdated = :time",
      ExpressionAttributeValues: {
        ":count": enrollmentCount,
        ":type": "stats",
        ":time": new Date().toISOString(),
      },
    }

    await docClient.send(new UpdateCommand(updateParams))
    console.log(`Updated enrollment count for ${courseId} to ${enrollmentCount}`)
  } catch (error) {
    console.error("Error updating enrollment count:", error)
    throw error
  }
}

// Function to update a student's grade average
async function updateStudentGradeAverage(studentId) {
  try {
    // In a real-world scenario, we would query all submissions for this student
    // and calculate the average grade
    // For this example, we'll just update a placeholder average

    const updateParams = {
      TableName: process.env.TABLE_NAME,
      Key: {
        pk: `user#${studentId}`,
        sk: "academic_stats",
      },
      UpdateExpression: "SET gradeAverage = :avg, entityType = :type, lastUpdated = :time",
      ExpressionAttributeValues: {
        ":avg": 85.5, // This would be calculated in a real scenario
        ":type": "academic_stats",
        ":time": new Date().toISOString(),
      },
    }

    await docClient.send(new UpdateCommand(updateParams))
    console.log(`Updated grade average for student ${studentId}`)
  } catch (error) {
    console.error("Error updating student grade average:", error)
    throw error
  }
}
