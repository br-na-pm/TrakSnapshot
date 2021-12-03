(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    nealj 
 * Created:   October 26, 2021/2:34 PM 
 * Converts epoch time to a string of a format similar to DATE_AND_TIME but without 
 * the ":" character. This is necessary for the recipe system. The desired format
 * is "YYYY_MM_DD HH_MM_SS".
 *********************************************************************************)

(* Converts a UDINT to a string of a format similar to DATE_AND_TIME but without the ":" character *)
FUNCTION_BLOCK EpochConverter
	CASE InternalState OF
		0:
			//Read the total number of seconds into the remainder variable
			//The offset is necessary because the calculation is off by 6hr 48min 34sec for an unknown reason
			IF (Offset = 0) THEN
				Offset := -24144;
			END_IF
			Remainder := Input + Offset;
			
			IF Execute THEN
				InternalState := 1;
			END_IF
			
		1:
			//1 year (365.24 days) = 31556926 seconds
			Year      := REAL_TO_UDINT(brmfloor((UDINT_TO_REAL(Remainder) / 31556926)));
			Remainder := Remainder - (Year   * 31556926);
			
			//1 month (30.44 days) = 2629743 seconds
			Month     := REAL_TO_UDINT(brmfloor((UDINT_TO_REAL(Remainder) / 2629743 )));
			Remainder := Remainder - (Month  * 2629743 );
			
			//1 day = 86400 seconds
			Day       := REAL_TO_UDINT(brmfloor((UDINT_TO_REAL(Remainder) / 86400   )));
			Remainder := Remainder - (Day    * 86400   );
			
			//1 hour = 3600 seconds
			Hour      := REAL_TO_UDINT(brmfloor((UDINT_TO_REAL(Remainder) / 3600    )));
			Remainder := Remainder - (Hour   * 3600    );
			
			//1 minute = 60 seconds
			Minute    := REAL_TO_UDINT(brmfloor((UDINT_TO_REAL(Remainder) / 60      )));
			Remainder := Remainder - (Minute * 60      );
			
			//Remainder is now the remaining seconds
			Second    := Remainder;
			
			//Now it must be factored in that these times represent the time since January 1, 1970 at 00:00
			Year  := Year  + 1970;
			Month := Month + 1;
			Day   := Day   + 1;
			
			InternalState := 2;
			
		2:
			//Clear the string
			brsmemset(ADR(DTString_For_Recipe),0,SIZEOF(DTString_For_Recipe));
			
			//Write "date"
			brsstrcat(ADR(DTString_For_Recipe),ADR(DateWord));
			brsstrcat(ADR(DTString_For_Recipe),ADR(UnderscoreCharacter));
			
			//Read in the year
			Year_Str := UDINT_TO_STRING(Year);
			brsstrcat(ADR(DTString_For_Recipe),ADR(Year_Str));
			brsstrcat(ADR(DTString_For_Recipe),ADR(UnderscoreCharacter));
			
			//Read in the month
			Month_Str := UDINT_TO_STRING(Month);
			brsstrcat(ADR(DTString_For_Recipe),ADR(Month_Str));
			brsstrcat(ADR(DTString_For_Recipe),ADR(UnderscoreCharacter));
			
			//Read in the day
			Day_Str := UDINT_TO_STRING(Day);
			brsstrcat(ADR(DTString_For_Recipe),ADR(Day_Str));
			brsstrcat(ADR(DTString_For_Recipe),ADR(SpaceCharacter));
			
			//Write "time"
			brsstrcat(ADR(DTString_For_Recipe),ADR(TimeWord));
			brsstrcat(ADR(DTString_For_Recipe),ADR(UnderscoreCharacter));
			
			//Read in the hour
			Hour_Str := UDINT_TO_STRING(Hour);
			brsstrcat(ADR(DTString_For_Recipe),ADR(Hour_Str));
			brsstrcat(ADR(DTString_For_Recipe),ADR(UnderscoreCharacter));
			
			//Read in the minute
			Minute_Str := UDINT_TO_STRING(Minute);
			brsstrcat(ADR(DTString_For_Recipe),ADR(Minute_Str));
			brsstrcat(ADR(DTString_For_Recipe),ADR(UnderscoreCharacter));
			
			//Read in the second
			Second_Str := UDINT_TO_STRING(Second);
			brsstrcat(ADR(DTString_For_Recipe),ADR(Second_Str));
			
			Execute       := FALSE;
			InternalState := 0;
		
	END_CASE
	
	
	
END_FUNCTION_BLOCK
