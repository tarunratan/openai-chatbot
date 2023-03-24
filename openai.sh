#!/bin/bash

# Set your API key and engine ID
SESSION_ID=$(uuidgen)
source .env
# Send the initial code to the OpenAI API
echo "lets start the conversation"

# Initialize the conversation history and counter
conversation_history=""
counter=0

# Fetch conversation history from PostgreSQL
get_conversation_history() {
  # Connect to PostgreSQL and fetch the conversation history for the given session_id
  # The session_id can be any unique identifier for the conversation, such as the user's ID or a randomly generated ID
  history_query="SELECT message FROM conversation_history WHERE session_id='*'"
  psql "postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE" -c "$history_query" -t | tr -d '[:space:]'
}
#echo get_conversation_history()
# Store conversation history in PostgreSQL
store_conversation_history() {
  # Connect to PostgreSQL and insert the new message into the conversation_history table
# store_query="INSERT INTO conversation_history (session_id, message) VALUES (:session_id, :message);" -v session_id=$SESSION_ID -v message="$conversation_history $RESPONSE"
  store_query="INSERT INTO conversation_history (session_id, message) VALUES ('$1', '$2')"
  psql "postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE" -c "$store_query" >/home/raviteja/Dropbox/tarunratan/openai/db.log
}

while true; do
  # Prompt the user for input
# Prompt for user input
#read -d ''  INPUT
read -p "> " INPUT
  # Check if the user wants to exit the session
  if [ "$INPUT" == "exit" ]; then
    break
  fi

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
     "model": "gpt-3.5-turbo",
     "messages": [{"role": "user", "content": "'"$INPUT"'"}],
     "temperature": 0
}')

RESPONSE=$(echo $RESPONSE |  jq -r '.choices[0].message.content')

 # Print the code
echo "AI: $RESPONSE"
RESPONSE=$(echo "$RESPONSE" |  sed "s/'/''/g")
  # Store the conversation history in PostgreSQL
 #  store_conversation_history "$SESSION_ID" "$conversation_history \"$RESPONSE\""
   store_conversation_history "$SESSION_ID" "$RESPONSE"
# Update the conversation history
conversation_history+="$RESPONSE"

done

