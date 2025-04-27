# Seed course data
resource "aws_dynamodb_table_item" "course_101" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/course_101.json")
}

# Seed student data for course 101
resource "aws_dynamodb_table_item" "student_201_in_course_101" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/student_201_in_course_101.json")
}

# Seed another student data for course 101
resource "aws_dynamodb_table_item" "student_202_in_course_101" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/student_202_in_course_101.json")
}

# Seed instructor data for course 101
resource "aws_dynamodb_table_item" "instructor_301_in_course_101" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/instructor_301_in_course_101.json")
}

# Seed assignment data for course 101
resource "aws_dynamodb_table_item" "assignment_401_in_course_101" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/assignment_401_in_course_101.json")
}

# Seed student's assignment submission for course 101
resource "aws_dynamodb_table_item" "submission_student_201_assignment_401" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/submission_student_201_assignment_401.json")
}

# Seed user item to demonstrate user-centric partition
resource "aws_dynamodb_table_item" "user_201_profile" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/user_201_profile.json")
}

# Seed orders for a user to demonstrate the sort key examples from the article
resource "aws_dynamodb_table_item" "user_201_order_1001" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/user_201_order_1001.json")
}

# Seed transaction for a user to demonstrate the sort key examples from the article
resource "aws_dynamodb_table_item" "user_201_transaction_2001" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/user_201_transaction_2001.json")
}

# Example for temporary data that would be removed by TTL
resource "aws_dynamodb_table_item" "temporary_data" {
  table_name = aws_dynamodb_table.university_table.name
  hash_key   = aws_dynamodb_table.university_table.hash_key
  range_key  = aws_dynamodb_table.university_table.range_key
  item       = file("${path.module}/data/temporary_data.json")
}
