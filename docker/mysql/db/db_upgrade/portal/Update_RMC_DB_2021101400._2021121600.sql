START TRANSACTION;

CREATE TABLE `comments` (
    `commentID` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `recordID` int(11) NOT NULL,
    `userID` int(11) NOT NULL,
    `comment` text NOT NULL,
    `dateCreated` timestamp NOT NULL DEFAULT current_timestamp(),
    `deleted` binary(1) NOT NULL DEFAULT '0',
    PRIMARY KEY (`commentID`),
    UNIQUE KEY `userID` (`userID`),
    UNIQUE KEY `recordID` (`recordID`)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

COMMIT;

/**** Revert DB ****
START TRANSACTION;

DROP TABLE IF EXISTS comments;

COMMIT;

*/