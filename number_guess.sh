#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN() {
  echo "Enter your username:"
  read NAME
  NAME_LENGTH=${#NAME}

  if [[ ! $NAME_LENGTH -le 50 ]] || [[ ! $NAME_LENGTH -gt 0 ]]
  then
    MAIN
  else
    USER_NAME=$(echo $($PSQL "SELECT username FROM users WHERE username='$NAME';") | sed 's/ //g')
    if [[ ! -z $USER_NAME ]]
    then
      USER_ID=$(echo $($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';") | sed 's/ //g')
      USER_NAME=$(echo $($PSQL "SELECT username FROM users WHERE user_id='$USER_ID';") | sed 's/ //g')
      GAMES_PLAYED=$(echo $($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID;") | sed 's/ //g')
      BEST_GAME=$(echo $($PSQL "SELECT MIN(best_game) FROM users LEFT JOIN games USING(user_id) WHERE user_id=$USER_ID;") | sed 's/ //g')
      echo "Welcome back, $USER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    else
      USER_NAME=$NAME
      echo -e "\nWelcome, $USER_NAME! It looks like this is your first time here."
    fi

    CORRECT_ANSWER=$(( $RANDOM % 1000 + 1 ))
    GUESS_COUNT=0
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT
  fi
}

INPUT_GUESS() {
  USER_NAME=$1
  CORRECT_ANSWER=$2
  GUESS_COUNT=$3
  USER_GUESS=$4

  if [[ -z $USER_GUESS ]]
  then
    echo "Guess the secret number between 1 and 1000:"
    read USER_GUESS
  else
    echo "That is not an integer, guess again:"
    read USER_GUESS
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  else
    CHECK_ANSWER $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  fi
}

CHECK_ANSWER() {
  USER_NAME=$1 
  CORRECT_ANSWER=$2 
  GUESS_COUNT=$3
  USER_GUESS=$4
  
  if [[ $USER_GUESS -lt $CORRECT_ANSWER ]]
  then
    echo "It's higher than that, guess again:"
    read USER_GUESS
  elif [[ $USER_GUESS -gt $CORRECT_ANSWER ]]
  then
    echo "It's lower than that, guess again:"
    read USER_GUESS
  else
    GUESS_COUNT=$GUESS_COUNT
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]
  then
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  elif [[ $USER_GUESS -lt $CORRECT_ANSWER ]] || [[ $USER_GUESS -gt $CORRECT_ANSWER ]]
  then
    CHECK_ANSWER $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USER_GUESS
  elif [[ $USER_GUESS -eq $CORRECT_ANSWER ]]
  then
    SAVE $USER_NAME $GUESS_COUNT
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $CORRECT_ANSWER. Nice job!"
  fi
}

SAVE() {
  USER_NAME=$1 
  GUESS_COUNT=$2

  CHECK_NAME=$($PSQL "SELECT username FROM users WHERE username='$USER_NAME';")
  if [[ -z $CHECK_NAME ]]
  then
    INSERT_NEW_USER=$($PSQL "INSERT INTO users(username, games_played) VALUES('$USER_NAME',1);")
  else
    GAMES_PLAYED=$(($($PSQL "SELECT games_played FROM users WHERE username='$USER_NAME';") + 1))
    UPDATE_EXIST_USER=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE username='$USER_NAME';")
  fi

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';")

  INSERT_GAME=$($PSQL "INSERT INTO games(user_id, best_game) VALUES($USER_ID, $GUESS_COUNT);")
  USER_NAME=$($PSQL "SELECT username FROM users WHERE user_id=$USER_ID;")
}

MAIN
