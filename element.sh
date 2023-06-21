#!/bin/bash
#read variables below from .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

#define PSQL variable to query db
PSQL="psql -X --username=$USERNAME --dbname=$DB_NAME --tuples-only -c"

ERROR_MSG(){
  # argument does not exist notify user
  echo "I could not find that element in the database."
}

SUCCESS_MSG() {
  #build full message
  echo "$1 $2 $3" | while read ATOMIC_NUMBER BAR NAME BAR SYMBOL TYPE BAR ATOMIC_MASS MELT BAR BOIL
  do
    #format variables removing spaces
    TYPE_FORMATTED=$(echo $TYPE | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
    ATOMIC_MASS_FORMATTED=$(echo $ATOMIC_MASS | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')    
    MELT_FORMATTED=$(echo $MELT | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
    BOIL_FORMATTED=$(echo $BOIL | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
    ATOMIC_NUMBER_FORMATTED=$(echo $ATOMIC_NUMBER | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//')
    # print full message
    echo "The element with atomic number $ATOMIC_NUMBER_FORMATTED is $NAME ($SYMBOL). It's a $TYPE_FORMATTED, with a mass of $ATOMIC_MASS_FORMATTED amu. $NAME has a melting point of $MELT_FORMATTED celsius and a boiling point of $BOIL_FORMATTED celsius."
  done
}

# if argument is not provided
if [[ -z $1 ]]
then
  echo -e "Please provide an element as an argument."
else
  # if argument is an integer
  if [[ $1 =~ ^[0-9]+$ ]]
  then
    # search by atomic number
    ELEMENT_DATA=$($PSQL "SELECT atomic_number, name, symbol FROM elements WHERE atomic_number=$1");
    # if atomic number does not exist
    if [[ -z $ELEMENT_DATA ]]
    then
      ERROR_MSG
    else
      # retrieve missing message parameters
      ELEMENT_TYPE_MASS=$($PSQL "SELECT type, atomic_mass FROM types LEFT JOIN properties USING(type_id) WHERE atomic_number=$1");
      ELEMENT_MELTING_BOILING=$($PSQL "SELECT melting_point_celsius, boiling_point_celsius FROM properties WHERE atomic_number=$1");
      SUCCESS_MSG "$ELEMENT_DATA $ELEMENT_TYPE_MASS $ELEMENT_MELTING_BOILING"
    fi
  fi
  # if argument is a word of length 1 or 2
  if [[ $1 =~ ^[a-zA-Z]{1,2}$ ]]
  then
    # search by symbol
    ATOMIC_NUMBER=$($PSQL "SELECT atomic_number FROM elements WHERE symbol='$1'");
    # if symbol does not exist
    if [[ -z $ATOMIC_NUMBER ]]
    then
      ERROR_MSG
    else
      # retrieve missing message parameters
      ELEMENT_DATA=$($PSQL "SELECT atomic_number, name, symbol FROM elements WHERE atomic_number=$ATOMIC_NUMBER");
      ELEMENT_TYPE_MASS=$($PSQL "SELECT type, atomic_mass FROM types LEFT JOIN properties USING(type_id) WHERE atomic_number=$ATOMIC_NUMBER");
      ELEMENT_MELTING_BOILING=$($PSQL "SELECT melting_point_celsius, boiling_point_celsius FROM properties WHERE atomic_number=$ATOMIC_NUMBER");
      SUCCESS_MSG "$ELEMENT_DATA $ELEMENT_TYPE_MASS $ELEMENT_MELTING_BOILING"
    fi
  fi
  # if argument is a word of length greater than 2
  if [[ $1 =~ ^[a-zA-Z]{3,}$ ]]
  then
    # search by element name
    ELEMENT_MELTING_BOILING=$($PSQL "SELECT melting_point_celsius, boiling_point_celsius FROM properties WHERE atomic_number=(SELECT atomic_number FROM elements WHERE name='$1')");
    if [[ -z $ELEMENT_MELTING_BOILING ]]
    then
      ERROR_MSG
    else
      # retrieve missing message parameters
      ELEMENT_DATA=$($PSQL "SELECT atomic_number, name, symbol FROM elements WHERE atomic_number=(SELECT atomic_number FROM elements WHERE name='$1')");
      ELEMENT_TYPE_MASS=$($PSQL "SELECT type, atomic_mass FROM types LEFT JOIN properties USING(type_id) WHERE atomic_number=(SELECT atomic_number FROM elements WHERE name='$1')");
      SUCCESS_MSG "$ELEMENT_DATA $ELEMENT_TYPE_MASS $ELEMENT_MELTING_BOILING"
    fi
  fi  
fi