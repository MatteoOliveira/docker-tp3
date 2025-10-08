<?php
    $mysqli = new mysqli('data', 'monuser', 'password');
    if (mysqli_connect_errno()) {
        printf("Connect failed: %s\n", mysqli_connect_error());
        exit();
    }

	if ($mysqli->query("INSERT INTO mabase.matable (compteur) SELECT count(*)+1 FROM mabase.matable;") === TRUE) {
	    printf("Count updated\n<br />", $result->num_rows);
	}

	if ($result = $mysqli->query("SELECT * FROM mabase.matable")) {
	    printf("Count : %d\n<br />", $result->num_rows);

	    /* Libération du jeu de résultats */
	    $result->close();
	}

    $mysqli->close();
?>