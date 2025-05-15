-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 05, 2025 at 03:19 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `charm_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `getActiveStreetsIncidents` (IN `streetJson` JSON)   BEGIN
  -- Temporary table to hold parsed street IDs
  CREATE TEMPORARY TABLE IF NOT EXISTS TempStreetIds (
    StreetId INT
  );

  -- Empty the table if it exists
  TRUNCATE TABLE TempStreetIds;

  -- Insert each street ID from the JSON array
  SET @i = 0;
  WHILE @i < JSON_LENGTH(streetJson) DO
    INSERT INTO TempStreetIds (StreetId)
    VALUES (CAST(JSON_UNQUOTE(JSON_EXTRACT(streetJson, CONCAT('$[', @i, ']'))) AS UNSIGNED));
    SET @i = @i + 1;
  END WHILE;

  -- Select incidents matching the street IDs
  SELECT 
    c.category,
    c.crimeType,
    c.crimeDescription,
    i.date,
    i.time,
    i.street
  FROM incident_data i
  JOIN crime_data c ON i.id = c.incidentId
  JOIN TempStreetIds t ON i.streetId = t.StreetId;

  -- Clean up
  DROP TEMPORARY TABLE IF EXISTS TempStreetIds;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllStreetsWithCrimeCount` ()   BEGIN
  SELECT 
    s.Id AS streetId,
    s.Name AS streetName,
    ST_AsGeoJSON(s.Geometry) AS geojson,
    GROUP_CONCAT(DISTINCT c.category ORDER BY c.category ASC SEPARATOR ', ') AS categories,
    GROUP_CONCAT(DISTINCT c.crimeType ORDER BY c.crimeType ASC SEPARATOR ', ') AS crimes,
    COUNT(c.id) AS crimeCount
  FROM streets s
  JOIN incident_data i ON s.Id = i.streetId
  JOIN crime_data c ON i.id = c.incidentId
  GROUP BY s.Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getCrimeByDayOfWeek` ()   BEGIN
    SELECT 
        DAYNAME(date) AS `Day`,
        COUNT(*) AS `Total Crimes`
    FROM incident_data
    GROUP BY `Day`
    ORDER BY `Total Crimes` DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getCrimesByCategory` (IN `crimeCategory` VARCHAR(100))   BEGIN
  SELECT 
    s.Id AS streetId,
    s.Name AS streetName,
    COUNT(c.id) AS crimeCount,
    GROUP_CONCAT(DISTINCT c.crimeType ORDER BY c.crimeType ASC SEPARATOR ', ') AS crimes
  FROM streets s
  JOIN incident_data i ON s.Id = i.streetId
  JOIN crime_data c ON i.id = c.incidentId
  WHERE c.category = crimeCategory
    AND c.crimeType IS NOT NULL
  GROUP BY s.Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getCrimesByStreetName` (IN `streetName` VARCHAR(255))   BEGIN
  SELECT 
    s.Id AS streetId,
    s.Name AS streetName,
    COUNT(c.id) AS crimeCount,
    GROUP_CONCAT(DISTINCT c.category ORDER BY c.category ASC SEPARATOR ', ') AS categories,
    GROUP_CONCAT(DISTINCT c.crimeType ORDER BY c.crimeType ASC SEPARATOR ', ') AS crimes
  FROM streets s
  JOIN incident_data i ON s.Id = i.streetId
  JOIN crime_data c ON i.id = c.incidentId
  WHERE s.Name = streetName
    AND c.category IS NOT NULL
    AND c.crimeType IS NOT NULL
  GROUP BY s.Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getIncidentReportsByStreetId` (IN `inputStreetId` INT)   BEGIN
  SELECT 
    i.id AS IncidentId,
    i.address AS Address,
    i.street AS Street,
    i.streetId AS StreetId,
    c.category AS `Category`,
    c.crimeType AS `Crime Type`,
    c.crimeDescription AS `Crime Description`,
    i.witnessName AS `Witness Name`,
    i.witnessAge AS `Witness Age`,
    i.witnessSex AS `Witness Sex`,
    i.contactNumber AS `Witness Contact`
  FROM incident_data i
  JOIN crime_data c ON i.id = c.incidentId
  WHERE i.streetId = inputStreetId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getMostActiveStreets` (IN `topN` INT)   BEGIN
  SELECT 
    s.Id AS streetId,
    s.Name AS streetName,
    COUNT(c.id) AS crimeCount
  FROM streets s
  JOIN incident_data i ON s.Id = i.streetId
  JOIN crime_data c ON i.id = c.incidentId
  GROUP BY s.Id
  ORDER BY crimeCount DESC
  LIMIT topN;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPeakCrimeTime` ()   BEGIN
    -- Peak Day
    SELECT 
        DAYNAME(date) AS `Peak Day`,
        COUNT(*) AS `Total Crimes`
    FROM incident_data
    GROUP BY `Peak Day`
    ORDER BY `Total Crimes` DESC
    LIMIT 1;

    -- Peak Hour
    SELECT 
        HOUR(time) AS `Peak Hour`,
        COUNT(*) AS `Total Crimes`
    FROM incident_data
    GROUP BY `Peak Hour`
    ORDER BY `Total Crimes` DESC
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPrevalentCrimeCategories` ()   BEGIN
    SELECT 
        category AS `Crime Category`,
        COUNT(*) AS `Total Reports`
    FROM crime_data
    GROUP BY category
    ORDER BY `Total Reports` DESC;
    
    SELECT 
        COUNT(*) AS `Total Crime Reports`
    FROM crime_data;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getRecentIncidents` ()   BEGIN
  SELECT 
    i.id AS IncidentId,
    i.street AS Street,
    i.date AS Date,
    i.time AS Time
  FROM incident_data i
  INNER JOIN crime_data c ON i.id = c.incidentId
  INNER JOIN streets s ON i.streetId = s.Id
  WHERE i.date >= CURDATE() - INTERVAL 15 DAY
  ORDER BY i.date DESC, i.time DESC;

  SELECT 
    COUNT(*) AS TotalRecentIncidents
  FROM incident_data i
  INNER JOIN crime_data c ON i.id = c.incidentId
  INNER JOIN streets s ON i.streetId = s.Id
  WHERE i.date >= CURDATE() - INTERVAL 15 DAY;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getStreetCrimeStats` ()   BEGIN
    -- Query 1: All streets with total crime count
    SELECT 
    i.street AS `Street`,
    COUNT(c.id) AS `Total Crimes`
	FROM incident_data i
	JOIN crime_data c ON i.id = c.incidentId
	GROUP BY i.street
	ORDER BY `Total Crimes` DESC;


    -- Query 2: Street with the most crimes
    SELECT 
        i.street AS `Most Affected Street`,
        COUNT(c.id) AS `Total Crimes`
    FROM incident_data i
    JOIN crime_data c ON i.id = c.incidentId
    GROUP BY i.street
    ORDER BY `Total Crimes` DESC
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getStreetsByDate` (IN `startDate` DATE, IN `endDate` DATE)   BEGIN
  SELECT 
    s.Id AS streetId,
    s.Name AS streetName,
    ST_AsGeoJSON(s.Geometry) AS geojson,
    COUNT(c.id) AS crimeCount,
    GROUP_CONCAT(DISTINCT c.category ORDER BY c.category ASC SEPARATOR ', ') AS categories,
    GROUP_CONCAT(DISTINCT c.crimeType ORDER BY c.crimeType ASC SEPARATOR ', ') AS crimes
  FROM streets s
  JOIN incident_data i ON s.Id = i.streetId
  JOIN crime_data c ON i.id = c.incidentId
  WHERE i.date BETWEEN startDate AND endDate
    AND c.category IS NOT NULL
    AND c.crimeType IS NOT NULL
  GROUP BY s.Id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `username` varchar(20) NOT NULL,
  `password` varchar(100) NOT NULL,
  `firstName` varchar(50) NOT NULL,
  `lastName` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `contact` varchar(15) NOT NULL,
  `role` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `username`, `password`, `firstName`, `lastName`, `email`, `contact`, `role`) VALUES
(1, 'admin', '$2y$10$WUN36RmFwcm53ongWn.PlOqhCIZwsdh.g9ZzeyKsgdAwejAMYBma2', 'Juls', 'Silvs', 'silvano.julius.kadusale@gmail.com', '09944902128', 'Admin'),
(5, 'rjayy', '$2y$10$lyQyd6xzXCGAK3n8vbRFherqA6pbTBG4Bam/.Y/HCDVybkpYcTIem', 'Rjay', 'Lorete', 'rjay@gmail.com', '09617836113', 'admin');

-- --------------------------------------------------------

--
-- Table structure for table `crime_data`
--

CREATE TABLE `crime_data` (
  `id` int(11) NOT NULL,
  `incidentId` int(11) NOT NULL,
  `category` varchar(100) NOT NULL,
  `crimeType` varchar(100) NOT NULL,
  `crimeDescription` text NOT NULL,
  `status` enum('Active','Archived') DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `crime_data`
--

INSERT INTO `crime_data` (`id`, `incidentId`, `category`, `crimeType`, `crimeDescription`, `status`) VALUES
(1001, 1001, 'Drug Activity', 'Public Drug Use', 'A public drug use incident reported involving suspicious activity.', 'Active'),
(1002, 1002, 'Drug Activity', 'Drug Paraphernalia Found', 'A drug paraphernalia incident reported involving suspicious activity.', 'Active'),
(1003, 1003, 'Environmental', 'Illegal Dumping', 'A illegal dumping incident reported involving suspicious activity.', 'Active'),
(1005, 1005, 'Traffic', 'Hit and Run', 'A hit and run incident reported involving suspicious activity.', 'Active'),
(1009, 1009, 'Disturbance', 'Public Intoxication', 'A public intoxication incident reported involving suspicious activity.', 'Active'),
(1011, 1011, 'Disturbance', 'Disorderly Conduct', 'A disorderly conduct incident reported involving suspicious activity.', 'Active'),
(1014, 1014, 'Theft', 'Pickpocketing', 'A pickpocketing incident reported involving suspicious activity.', 'Active'),
(1015, 1015, 'Theft', 'Bike Theft', 'A bicycle theft incident reported involving suspicious activity.', 'Active'),
(1016, 1016, 'Vandalism', 'Public Property Damage', 'A vehicle vandalism incident reported involving suspicious activity.', 'Active'),
(1022, 1022, 'Vandalism', 'Public Property Damage', 'A public property damage incident reported involving suspicious activity.', 'Active'),
(1024, 1024, 'Violence', 'Assault', 'A assault incident reported involving suspicious activity.', 'Active'),
(1025, 1025, 'Drug Activity', 'Overdose Incident', 'A substance abuse incident reported involving suspicious activity.', 'Active'),
(1026, 1026, 'Vandalism', 'Graffiti', 'A graffiti incident reported involving suspicious activity.', 'Active'),
(1027, 1027, 'Traffic', 'Hit and Run', 'A hit and run incident reported involving suspicious activity.', 'Active'),
(1030, 1030, 'Drug Activity', 'Drug Transaction', 'A drug possession incident reported involving suspicious activity.', 'Active'),
(1032, 1032, 'Drug Activity', 'Overdose Incident', 'A substance abuse incident reported involving suspicious activity.', 'Active'),
(1034, 1034, 'Traffic', 'Hit and Run', 'A hit and run incident reported involving suspicious activity.', 'Active'),
(1036, 1036, 'Traffic', 'Wrong Way Driving', 'A improper lane change incident reported involving suspicious activity.', 'Active'),
(1037, 1037, 'Vandalism', 'Graffiti', 'A graffiti incident reported involving suspicious activity.', 'Active'),
(1038, 1038, 'Drug Activity', 'Overdose Incident', 'A substance abuse incident reported involving suspicious activity.', 'Active'),
(1040, 1040, 'Drug Activity', 'Public Drug Use', 'A public drug use incident reported involving suspicious activity.', 'Active'),
(1042, 1042, 'Theft', 'Bag Snatching', 'A snatching incident reported involving suspicious activity.', 'Active'),
(1043, 1043, 'Traffic', 'Driving Without Headlights', 'A driving without license incident reported involving suspicious activity.', 'Active'),
(1045, 1045, 'Drug Activity', 'Drug Transaction', 'A drug possession incident reported involving suspicious activity.', 'Active'),
(1046, 1046, 'Traffic', 'Running Red Light', 'A red light violation incident reported involving suspicious activity.', 'Active'),
(1048, 1048, 'Environmental', 'Noise Pollution', 'A noise pollution incident reported involving suspicious activity.', 'Active'),
(1049, 1049, 'Disturbance', 'Public Intoxication', 'A public intoxication incident reported involving suspicious activity.', 'Active'),
(1050, 1050, 'Violence', 'Verbal Threats', 'Students verbally threatening each other.', 'Active'),
(1051, 1051, 'Drug Activity', 'Drug Transaction', 'Spotted 2 suspects conducting a drug transaction near GMAS Computer Shop.', 'Active'),
(1052, 1052, 'Theft', 'Pickpocketing', 'A male victim has been pickpocketed.', 'Active'),
(1053, 1053, 'Violence', 'Sexual Assault', 'A male suspect has been seen sexually assaulting a woman in the streets.', 'Active'),
(1054, 1054, 'Suspicious', 'Suspicious Vehicle', 'Suspicious vehicle spotted around the area.', 'Active'),
(1055, 1055, 'Disturbance', 'Noise Complaint', 'Witness complains about the unbearable noise happening around the area', 'Active'),
(1056, 1056, 'Drug Activity', 'Drug Transaction', 'Two male suspects found doing what seems to be a drug transaction.', 'Active'),
(1057, 1057, 'Traffic', 'Hit and Run', 'A fast-moving vehicle collided with the victim.', 'Active'),
(1058, 1058, 'Theft', 'Bag Snatching', 'A person snatched the belonging of a woman in the street.', 'Active'),
(1059, 1059, 'Theft', 'Bag Snatching', 'Snatched the bag of a woman', 'Active'),
(1060, 1060, 'Theft', 'Pickpocketing', 'Saw a kid pickpocket a woman buying street foods.', 'Active'),
(1061, 1061, 'Theft', 'Bag Snatching', 'The victim\'s bag was snatched by an unidentified man.', 'Active'),
(1062, 1062, 'Violence', 'Street Fight', 'The victim is mildly injured because of the street fight.', 'Active'),
(1063, 1063, 'Vandalism', 'Graffiti', 'An illegal graffiti was found in an alley.', 'Active'),
(1064, 1064, 'Drug Activity', 'Public Drug Use', 'A youth is spotted taking a substance in public', 'Active'),
(1065, 1065, 'Violence', 'Mugging', 'Victim got caught in the crossfire', 'Active');

-- --------------------------------------------------------

--
-- Table structure for table `incident_data`
--

CREATE TABLE `incident_data` (
  `id` int(11) NOT NULL,
  `address` varchar(255) NOT NULL,
  `street` varchar(100) NOT NULL,
  `streetId` int(11) NOT NULL,
  `date` date NOT NULL,
  `time` time NOT NULL,
  `witnessName` varchar(100) NOT NULL,
  `witnessAge` int(11) NOT NULL,
  `witnessSex` enum('Male','Female') NOT NULL,
  `contactNumber` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `incident_data`
--

INSERT INTO `incident_data` (`id`, `address`, `street`, `streetId`, `date`, `time`, `witnessName`, `witnessAge`, `witnessSex`, `contactNumber`) VALUES
(1000, '751 Diligence Street', 'Diligence Street', 2, '2025-02-11', '00:16:00', 'John Doe 0', 40, 'Female', '09171447153'),
(1001, '698 Bougainvilla Street', 'Bougainvilla Street', 11, '2024-08-29', '16:21:00', 'John Doe 1', 46, 'Female', '09179192333'),
(1002, '327 Love Street', 'Love Street', 9, '2025-03-26', '01:25:00', 'John Doe 2', 58, 'Female', '09176473868'),
(1003, '591 Goodwill Avenue', 'Goodwill Avenue', 7, '2024-05-08', '12:10:00', 'John Doe 3', 62, 'Female', '09172241483'),
(1004, '688 Bougainvilla Street', 'Bougainvilla Street', 11, '2024-06-09', '23:24:00', 'John Doe 4', 53, 'Female', '09178696843'),
(1005, '556 Diligence Street', 'Diligence Street', 2, '2024-08-21', '15:06:00', 'John Doe 5', 36, 'Male', '09178009231'),
(1006, '996 Bougainvilla Street', 'Bougainvilla Street', 11, '2025-03-23', '04:04:00', 'John Doe 6', 24, 'Male', '09175608309'),
(1007, '940 Charity Street', 'Charity Street', 3, '2025-04-05', '04:53:00', 'John Doe 7', 41, 'Male', '09176340685'),
(1008, '735 Efficiency Street', 'Efficiency Street', 6, '2024-05-29', '15:02:00', 'John Doe 8', 49, 'Female', '09172925755'),
(1009, '793 Efficiency Street', 'Efficiency Street', 6, '2024-08-16', '08:48:00', 'John Doe 9', 65, 'Female', '09172959077'),
(1010, '701 Diligence Street', 'Diligence Street', 2, '2024-05-17', '18:11:00', 'John Doe 10', 61, 'Male', '09172927372'),
(1011, '284 Bougainvilla Street', 'Bougainvilla Street', 11, '2025-04-13', '20:23:00', 'John Doe 11', 30, 'Male', '09178034264'),
(1012, '649 Obedience Street', 'Obedience Street', 10, '2024-09-10', '05:41:00', 'John Doe 12', 26, 'Male', '09179250724'),
(1013, '274 Goodwill Avenue', 'Goodwill Avenue', 7, '2024-09-01', '12:11:00', 'John Doe 13', 51, 'Male', '09174451155'),
(1014, '947 Bougainvilla Street', 'Bougainvilla Street', 11, '2025-01-20', '15:08:00', 'John Doe 14', 69, 'Female', '09178572353'),
(1015, '798 Obedience Street', 'Obedience Street', 10, '2024-07-25', '19:30:00', 'John Doe 15', 34, 'Male', '09174945251'),
(1016, '771 Charity Street', 'Charity Street', 3, '2025-01-07', '22:16:00', 'John Doe 16', 51, 'Female', '09176353885'),
(1017, '527 Love Street', 'Love Street', 9, '2024-06-09', '00:42:00', 'John Doe 17', 56, 'Female', '09172271856'),
(1018, '506 Efficiency Street', 'Efficiency Street', 6, '2024-06-03', '17:34:00', 'John Doe 18', 60, 'Female', '09177710432'),
(1019, '300 West Los Angeles Street', 'West Los Angeles Street', 1, '2024-07-15', '12:49:00', 'John Doe 19', 34, 'Female', '09175954471'),
(1020, '489 Goodwill Avenue', 'Goodwill Avenue', 7, '2024-07-02', '19:59:00', 'John Doe 20', 38, 'Female', '09174865781'),
(1021, '776 Love Street', 'Love Street', 9, '2024-09-06', '00:24:00', 'John Doe 21', 59, 'Male', '09175563741'),
(1022, '600 Efficiency Street', 'Efficiency Street', 6, '2024-05-21', '10:18:00', 'John Doe 22', 38, 'Female', '09171961335'),
(1023, '686 Goodwill Avenue', 'Goodwill Avenue', 7, '2024-07-17', '18:04:00', 'John Doe 23', 34, 'Female', '09177448211'),
(1024, '109 Bougainvilla Street', 'Bougainvilla Street', 11, '2024-04-30', '13:14:00', 'John Doe 24', 51, 'Male', '09172522813'),
(1025, '727 Diligence Street', 'Diligence Street', 2, '2024-08-27', '16:26:00', 'John Doe 25', 33, 'Male', '09171580663'),
(1026, '100 Charity Street', 'Charity Street', 3, '2024-07-22', '21:48:00', 'John Doe 26', 48, 'Male', '09175615942'),
(1027, '678 West Los Angeles Street', 'West Los Angeles Street', 1, '2024-09-23', '22:53:00', 'John Doe 27', 29, 'Male', '09175395656'),
(1028, '146 Obedience Street', 'Obedience Street', 10, '2024-10-07', '22:57:00', 'John Doe 28', 45, 'Male', '09178890818'),
(1029, '957 Faith Street', 'Faith Street', 8, '2025-03-20', '19:19:00', 'John Doe 29', 55, 'Male', '09179115439'),
(1030, '876 Diligence Street', 'Diligence Street', 2, '2025-03-30', '15:11:00', 'John Doe 30', 46, 'Male', '09171638465'),
(1031, '121 Industrious Street', 'Industrious Street', 4, '2025-02-08', '15:30:00', 'John Doe 31', 28, 'Male', '09177941858'),
(1032, '545 Goodwill Avenue', 'Goodwill Avenue', 7, '2024-07-21', '07:40:00', 'John Doe 32', 24, 'Male', '09178821118'),
(1033, '103 Love Street', 'Love Street', 9, '2025-01-05', '20:00:00', 'John Doe 33', 65, 'Female', '09174861897'),
(1034, '452 Diligence Street', 'Diligence Street', 2, '2024-10-19', '23:44:00', 'John Doe 34', 45, 'Male', '09172900072'),
(1035, '657 Industrious Street', 'Industrious Street', 4, '2025-02-26', '17:37:00', 'John Doe 35', 66, 'Male', '09173251949'),
(1036, '187 Goodwill Avenue', 'Goodwill Avenue', 7, '2024-08-10', '20:21:00', 'John Doe 36', 63, 'Male', '09177540033'),
(1037, '694 West Los Angeles Street', 'West Los Angeles Street', 1, '2025-03-28', '08:22:00', 'John Doe 37', 18, 'Male', '09178762999'),
(1038, '355 Charity Street', 'Charity Street', 3, '2025-03-01', '20:19:00', 'John Doe 38', 28, 'Female', '09174851920'),
(1039, '809 Diligence Street', 'Diligence Street', 2, '2024-10-29', '18:24:00', 'John Doe 39', 23, 'Female', '09178889053'),
(1040, '184 Goodwill Avenue', 'Goodwill Avenue', 7, '2024-05-28', '04:19:00', 'John Doe 40', 40, 'Male', '09174988854'),
(1041, '986 West Los Angeles Street', 'West Los Angeles Street', 1, '2024-05-09', '15:42:00', 'John Doe 41', 62, 'Female', '09175678172'),
(1042, '543 West Los Angeles Street', 'West Los Angeles Street', 1, '2024-09-28', '13:03:00', 'John Doe 42', 42, 'Male', '09173579327'),
(1043, '579 Charity Street', 'Charity Street', 3, '2024-07-07', '00:24:00', 'John Doe 43', 53, 'Female', '09177805536'),
(1044, '487 Faith Street', 'Faith Street', 8, '2024-06-08', '02:17:00', 'John Doe 44', 48, 'Male', '09171327986'),
(1045, '484 Love Street', 'Love Street', 9, '2024-04-27', '15:48:00', 'John Doe 45', 61, 'Female', '09173961561'),
(1046, '971 Industrious Street', 'Industrious Street', 4, '2024-11-05', '18:11:00', 'John Doe 46', 54, 'Female', '09171092657'),
(1047, '906 Diligence Street', 'Diligence Street', 2, '2024-08-13', '05:04:00', 'John Doe 47', 21, 'Female', '09175357757'),
(1048, '625 Efficiency Street', 'Efficiency Street', 6, '2024-04-25', '21:56:00', 'John Doe 48', 22, 'Female', '09176163167'),
(1049, '610 Diligence Street', 'Diligence Street', 2, '2025-01-26', '11:40:00', 'John Doe 49', 65, 'Male', '09174473996'),
(1050, 'First Street, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'First Street', 192, '2025-04-19', '01:02:00', 'Julius Silvano', 19, 'Male', '09944902128'),
(1051, 'Rockville Avenue, Rockville, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Rockville Avenue', 203, '2025-04-19', '11:31:00', 'Julius Silvano', 19, 'Male', '09944902128'),
(1052, 'Rockville Avenue, Rockville, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Rockville Avenue', 682, '2025-04-19', '16:01:00', 'Julius Silvano', 19, 'Male', '09944902128'),
(1053, 'Emerald Street, Rockville, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Emerald Street', 119, '2025-04-19', '16:03:00', 'Julius Silvano', 19, 'Male', '09944902128'),
(1054, 'Quezon Street, Doña Faustina, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Quezon Street', 136, '2025-04-19', '16:20:00', 'Julius Silvano', 19, 'Male', '09944902128'),
(1055, 'Emerald Street, Rockville, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Emerald Street', 119, '2025-04-19', '17:23:00', 'Julius Silvano', 19, 'Male', '09944902128'),
(1056, 'Quezon Street, Doña Faustina, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Recto Street', 145, '2025-04-19', '18:02:00', 'Julius Silvano', 19, 'Male', '09944902128'),
(1057, 'Goldilocks, Quirino Highway, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Quirino Highway', 1072, '2025-04-21', '22:23:00', 'Rjay Lorete', 20, 'Male', '09945123544'),
(1058, 'San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Unnamed Road / Street', 771, '2025-04-21', '22:33:00', 'Rjay Lorete', 20, 'Male', '09944902128'),
(1059, 'Diamond Street, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Diamond Street', 121, '2025-04-22', '07:54:00', 'Rjay Lorete', 20, 'Male', '09617836113'),
(1060, 'Colegio de San Bartolome De Novaliches, Pablo dela Cruz Street, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1100, Philippines', 'Unnamed Road / Street', 327, '2025-04-22', '08:47:00', 'Julius Silvano', 19, 'Male', '09945123544'),
(1061, 'Gold Street, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Gold Street', 282, '2025-04-28', '00:55:00', 'Khylle Paano', 20, 'Male', ''),
(1062, 'Diamond Street, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Diamond Street', 121, '2025-04-28', '00:59:00', 'Miko Santos', 20, 'Male', ''),
(1063, 'Gold Street, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Gold Street', 282, '2025-04-28', '01:05:00', 'Kristine Camille Gallardo', 20, 'Female', ''),
(1064, 'Gold Street, San Bartolome, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Gold Street', 282, '2025-04-28', '01:08:00', 'Julius Silvano', 19, 'Male', ''),
(1065, 'Emerald Street, Rockville, 5th District, Quezon City, Eastern Manila District, Metro Manila, 1116, Philippines', 'Emerald Street', 119, '2025-04-28', '01:05:00', 'Kristine Camille Gallardo', 20, 'Female', '');

--
-- Triggers `incident_data`
--
DELIMITER $$
CREATE TRIGGER `trg_incident_update` AFTER UPDATE ON `incident_data` FOR EACH ROW BEGIN
  DECLARE old_json TEXT;
  DECLARE new_json TEXT;

  SET old_json = JSON_OBJECT(
    'address', OLD.address,
    'street', OLD.street,
    'date', OLD.date,
    'time', OLD.time,
    'witnessName', OLD.witnessName,
    'witnessAge', OLD.witnessAge,
    'witnessSex', OLD.witnessSex,
    'contactNumber', OLD.contactNumber
  );

  SET new_json = JSON_OBJECT(
    'address', NEW.address,
    'street', NEW.street,
    'date', NEW.date,
    'time', NEW.time,
    'witnessName', NEW.witnessName,
    'witnessAge', NEW.witnessAge,
    'witnessSex', NEW.witnessSex,
    'contactNumber', NEW.contactNumber
  );

  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data)
  VALUES (@current_user_id, 'UPDATE', 'incident_data', OLD.id, old_json, new_json);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `streets`
--

CREATE TABLE `streets` (
  `Id` int(11) NOT NULL,
  `Name` varchar(255) DEFAULT NULL,
  `Highway` varchar(100) DEFAULT NULL,
  `Oneway` varchar(10) DEFAULT NULL,
  `OldName` varchar(255) DEFAULT NULL,
  `StreetId` varchar(100) DEFAULT NULL,
  `Geometry` geometry NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `streets`
--

INSERT INTO `streets` (`Id`, `Name`, `Highway`, `Oneway`, `OldName`, `StreetId`, `Geometry`) VALUES
(1, 'West Los Angeles Street', 'residential', NULL, 'Sampaguita', 'way/23213805', 0x00000000010200000006000000751f80d426415e40cdb1bcab1e6c2d408b2194522b415e4043aed4b3206c2d40d1cabdc02c415e4042661d44216c2d406ba395d63a415e406e9e8fd7286c2d4041bd74ee51415e4006de24613a6c2d400f52a68757415e40d4bda9a33e6c2d40),
(2, 'Diligence Street', 'residential', NULL, NULL, 'way/23213808', 0x0000000001020000001a000000d0decfdf3a415e40c4c02962c7692d402ab7a3ee39415e4041727cfec5692d40f4baeaa639415e40fac5b656c5692d40069ca56439415e40a857ca32c4692d40fb35a33039415e408b1645b4c2692d40602cc20339415e4038f00f00c1692d407e5c76e338415e4021b47977bf692d406c088ecb38415e401682c1dabd692d4013ee3ac038415e40c35b8c26bc692d403de64d8f37415e40e2009fc48c692d400dd87a2b37415e404811be9c7e692d4008d6276f36415e40cb8a3ca473692d40c8f5a56d32415e4031b43a3943692d409bae27ba2e415e40a4dc22d51c692d4084ba48a12c415e4061bbc50d09692d401938a0a52b415e40377b5688fd682d402085460b2b415e40d0e8b3a8f4682d400ebe30992a415e407033260eea682d408068418328415e40ac61759abb682d40575f5d1528415e40e0ec7b79a6682d40c16ed8b628415e4090a1630795682d40a999ffa12a415e40d2c9ada470682d40013beddf2b415e40571e49ee55682d40d15790662c415e40ad5c5e6f51682d403074362e2d415e40ef6bc94f4f682d409bf6de292e415e4096687f564f682d40),
(3, 'Charity Street', 'residential', NULL, NULL, 'way/23213810', 0x00000000010200000009000000f75d6cb562415e406d2123fb7b682d40f849ffdc61415e40a4a833f790682d4022cc481861415e40dcdf8f91a2682d4081d71d4160415e406d4210d6b5682d40be6bd0975e415e40485b4bb7db682d40b33918fb5c415e401eff058200692d40fb05bb615b415e407cce82f524692d400992d2c757415e40f96706f181692d4015e4672357415e4008173c9688692d40),
(4, 'Industrious Street', 'residential', NULL, NULL, 'way/23213848', 0x000000000102000000080000001208855245415e404c930843d3682d403ca1d79f44415e406a036674f6682d40ea7d3e2542415e405ae6bee666692d409e73017940415e4043588d25ac692d40bceb6cc83f415e4020b18284cd692d40da63d8173f415e4088e5852aeb692d40336722113f415e4098d4754ded692d40e07fd01f3f415e40f06f2b18f0692d40),
(5, 'Diligence Street', 'residential', NULL, NULL, 'way/23213851', 0x0000000001020000000d000000d0decfdf3a415e40c4c02962c7692d40bceb6cc83f415e4020b18284cd692d406c9ed96443415e40c425c79dd2692d40ae45b01644415e400585e6dfd3692d404eb0a48144415e406902a0e5d4692d404230fd0145415e40394ab956d6692d400b1467fb46415e40e2a30fa7dd692d403506425747415e403b17ebc0de692d4011ffb0a547415e4028c0666fdf692d40645930f147415e407cbec172df692d40a58dd94848415e40e113a1c7de692d4052d4997b48415e404d6e6f12de692d407e4056a64e415e40a3e5400fb5692d40),
(6, 'Efficiency Street', 'residential', 'yes', NULL, 'way/23213852', 0x000000000102000000040000009dc9ed4d42415e4096b43dd57c682d40c500892650415e40f4d6659d96682d40a53d6f745f415e40b009c446b4682d4081d71d4160415e406d4210d6b5682d40),
(7, 'Goodwill Avenue', 'residential', NULL, NULL, 'way/23213854', 0x00000000010200000002000000449b2d6a41415e40483a5edca1682d40a999ffa12a415e40d2c9ada470682d40),
(8, 'Faith Street', 'residential', 'yes', NULL, 'way/23213858', 0x00000000010200000007000000264003a040415e40ec055559ca682d4079aeefc341415e409dec0b8dcc682d401208855245415e404c930843d3682d40ebebaf0d4b415e400b09185dde682d40dc5328c151415e40dbb5ce09eb682d406c5f402f5c415e405ac1cafcfe682d40b33918fb5c415e401eff058200692d40),
(9, 'Love Street', 'residential', NULL, NULL, 'way/23213864', 0x000000000102000000030000000ebe30992a415e407033260eea682d40f58997022d415e40576f1e98ed682d405757aab03e415e4002a8983913692d40),
(10, 'Obedience Street', 'residential', NULL, NULL, 'way/23213865', 0x000000000102000000040000009bae27ba2e415e40a4dc22d51c692d40ff2be1bf2f415e40c23d85121c692d40e1deeb5a31415e40f14520031e692d4069520aba3d415e4035a440553b692d40),
(11, 'Bougainvilla Street', 'service', NULL, NULL, 'way/23213876', 0x0000000001020000000d0000004b1d893cee415e4012baf0283a672d40240c0396dc415e40228d0a9c6c672d40219221c7d6415e40e3c4573b8a672d408decef11d6415e40f3db210f8e672d4018cb9992d1415e408dc00e52a6672d402c2e8ecacd415e4071917bbaba672d40f7ef5586cc415e400e29ab8ec1672d40cd7344becb415e40a76b370bc5672d40bcf4e5bbca415e40580a37cfc7672d40280a99d0c9415e408da72f95c8672d40990d32c9c8415e40c41c4eaac7672d4017a87b53c7415e404e68ed11c5672d40e4a08499b6415e4039a2d68fa8672d40),
(12, NULL, 'service', NULL, NULL, 'way/23213886', 0x0000000001020000000f000000e4a08499b6415e4039a2d68fa8672d40b1a54753bd415e40b6f86fb955672d406849360dc0415e401c672ecb32672d409751d1fdc1415e4039b69e211c672d40b40584d6c3415e4048bb760e0a672d40bf7c57a9c5415e40c0ba8509fe662d4028c819d4c8415e401be1a3b4ed662d406d3189c4ce415e408ad1cec4cf662d40d7998c74d0415e4029441bdbc6662d40e801e264d1415e4086a7fc10c0662d40ee485057d2415e40a45b0aa3b4662d40bb1f01edd8415e4033141c0357662d409ccf6f4edb415e40df2ea0bc34662d40017ed7b1db415e400bda9a632f662d40d19a7a38dc415e40f5752a2a2c662d40),
(13, 'Talisay Street', 'service', NULL, NULL, 'way/23213891', 0x0000000001020000000d00000003e154b5ee415e40c8e9904028682d40c1334690ef415e40081edfde35682d40cc37ec08f1415e40d9bfa1a64c682d40c6466aebf1415e400588821953682d40928daca1f9415e40dd96c80567682d405c74b2d4fa415e407bbe66b96c682d409ded7662fb415e4036b7f8ca72682d405039268bfb415e407b93951579682d406231ea5afb415e40fa111a1c80682d4086f35fd6fa415e40f1ac93e986682d4055d6db0bf1415e4026529acde3682d409dfb0681f0415e4078a0a932e7682d40bb8a7be2ef415e40838aaa5fe9682d40),
(14, NULL, 'service', NULL, NULL, 'way/23213894', 0x00000000010200000006000000e9fcca39e7415e40a4e6069ed6682d4003e154b5ee415e40c8e9904028682d401adb6b41ef415e40857588241f682d400856d5cbef415e4030f2b22616682d40a3e9ec64f0415e4018e9ea330c682d406ccaba24f3415e40edc15a6bde672d40),
(15, NULL, 'service', NULL, NULL, 'way/23213896', 0x00000000010200000002000000f99dcb79eb415e40e675c4211b682d409192c3cce3415e4078ae940acf682d40),
(16, NULL, 'service', NULL, NULL, 'way/23213899', 0x000000000102000000020000004270a653e8415e40d6f95c120c682d409919ec3ce0415e4029e8f692c6682d40),
(17, NULL, 'service', NULL, NULL, 'way/23213900', 0x0000000001020000000200000045cda156e2415e40b6018ef3ed672d40674c1cd4d9415e40748fb63bb5682d40),
(18, NULL, 'service', NULL, NULL, 'way/23213903', 0x00000000010200000002000000dfb8d628b5415e4006989e550b692d40e82ff488d1415e4063145f48e2682d40),
(19, NULL, 'service', NULL, NULL, 'way/23213908', 0x00000000010200000003000000b0822914b3415e40718b9e002f682d40778d4c76a2415e40e8e5666e74682d40fda8e1b691415e40b8fbc165ba682d40),
(20, 'Begonia Street', 'service', NULL, NULL, 'way/23213909', 0x0000000001020000000300000070e360808e415e405f84df3c8b682d40268458479f415e409aa03ce246682d40cae77008b0415e40b34e4b62ff672d40),
(21, NULL, 'service', NULL, NULL, 'way/23213910', 0x0000000001020000000200000046e63686a5415e40960bf038a0682d408a2947b794415e405b5f24b4e5682d40),
(22, NULL, 'service', NULL, NULL, 'way/23213913', 0x00000000010200000003000000e90c8cbcac415e4035705177af682d40d2408754ac415e409d26d824e4682d40383dde9aaa415e40f8f65388ec682d40),
(23, NULL, 'service', NULL, NULL, 'way/23213915', 0x00000000010200000009000000045b80118f415e40861e317a6e692d4034b10ae58e415e406e066e9340692d4046a9ceb48e415e40fb21365838692d40abfead098e415e4006a799492f692d40e4fb3d0c88415e40e01c644804692d40d92846f185415e40c97b3084f7682d4086ff740385415e402022da33f0682d40da006c4084415e40fa360e06e8682d407730629f80415e40ef4806cab7682d40),
(24, NULL, 'service', NULL, NULL, 'way/23213916', 0x00000000010200000005000000d92846f185415e40c97b3084f7682d40c43d3b8581415e40777aefb95d692d40a07e614381415e4007e863e366692d40f365b33481415e402cfb09c270692d40bef3305981415e408c40063c7a692d40),
(25, NULL, 'service', NULL, NULL, 'way/23213917', 0x0000000001020000000b000000671998cb7c415e4060257a747e692d409c71755b7d415e40777aefb95d692d404feb36a87d415e4019bd642d4f692d405a4e9da27e415e409c61b4d837692d408f19a88c7f415e402a638dc415692d40dc12149a7f415e402b46a7f809692d40aded37247f415e40de324c12f0682d408ad5d5d37d415e40612a4712ce682d405a3a30ca7d415e40f92f1004c8682d406cea3c2a7e415e406d173f32c2682d407730629f80415e40ef4806cab7682d40),
(26, NULL, 'service', NULL, NULL, 'way/23213918', 0x00000000010200000008000000fd71569f86415e406359d537d5672d40a6fc5a4d8d415e40df65d01acd672d40d9bbf55091415e4017d3f13dc8672d40de44e33f93415e40e8ca564dc6672d40ef05c13e95415e4071f618f6c5672d40184e886f97415e40e8829fddc6672d405854c4e9a4415e40261296c2cd672d40bfa4e7ccac415e40a0ab0892d2672d40),
(27, NULL, 'service', NULL, NULL, 'way/23213925', 0x00000000010200000005000000b0e99cfa9b415e40ee2affb517682d40268458479f415e409aa03ce246682d40778d4c76a2415e40e8e5666e74682d4046e63686a5415e40960bf038a0682d40ecc5ab07a7415e40cd4a49c5b5682d40),
(28, 'Holy Cross Road', 'unclassified', NULL, NULL, 'way/23213929', 0x0000000001020000000d000000c741ae79fa415e40404bfcf61a672d4006088b2fff415e407fdde9ce13672d40217c838a05425e40361c3b4d0b672d40a15f00860a425e409dd9aed007672d4047c60f3a0d425e40d276a79608672d402e36525b0f425e40bf47fdf50a672d40f0ac383014425e4067599cd612672d4018aaacb717425e40bc94ba641c672d40bc4f9f2e1c425e409703988d29672d40b51c435b29425e40e25bb3f050672d40e4277a852a425e40c3222b6453672d40eab303ae2b425e407699507754672d40182c30bf2e425e401bbee02e56672d40),
(29, 'Pablo dela Cruz Street', 'tertiary', 'no', NULL, 'way/23213934', 0x0000000001020000004a0000002411757a39425e409c5c42f45a672d40fb35a33039425e404a65e5f27a672d40e35295b638425e40dcf63deaaf672d404e7cb5a338425e40520548d9c7672d404860bd9b38425e40be0c6bcfd1672d40d12cbfc238425e403a90f5d4ea672d404818062c39425e4073918ce612682d40ef14bc3239425e408af5fc1f16682d4048d04ebc39425e40b41c8de843682d40fa04f5d239425e408c56a4784b682d40956afa473a425e402bf5d14e72682d409bcb0d863a425e401578825891682d40a01518b23a425e406be56f8cae682d40b857e6ad3a425e408c7b9862b3682d40b840dd9b3a425e4025e6fe8fb8682d401e4e05813a425e40e773ee76bd682d40be00b15b3a425e40fcb781f1c2682d40e926d64e39425e40d4731c89e1682d405b3343f435425e402e0fe37f3c692d404a10093a35425e40caa31b6151692d4081a268d432425e40eca2e8818f692d4075e0415832425e40646c32f499692d40c3f6eeea30425e400fd07d39b3692d408ee6c8ca2f425e402c56c334c2692d404799c3a42e425e40cc6a7011ce692d40a83407ad2c425e404e8e4cd1db692d406f17f5a427425e4084ea8b29fd692d400734c7a821425e40adfc3218236a2d40ddfcd01621425e40d427b9c3266a2d40f535261f16425e403e80a037706a2d406cf992d714425e407b7f283d786a2d40433866d913425e407efca5457d6a2d408bea63f412425e40c4888e2e806a2d405cf635dc11425e405febf769816a2d40b6b700d910425e40dbc424b7816a2d40f2d5e99b0f425e404d24e2f7806a2d403ad09e260e425e4095f0845e7f6a2d40658396bf0c425e40e3c116bb7d6a2d40837467dc0a425e40322317f77a6a2d40149d1b8906425e401e6ff25b746a2d4063e4767904425e407fdfbf79716a2d40bd7acb8b02425e409dd090966f6a2d4017563bd400425e4014ed855d6f6a2d40d1afad9ffe415e407f6f2e59706a2d4090af4edffc415e40c543ceb1726a2d40b73bb544f8415e40022379f87c6a2d40583c5002f6415e402299c40f846a2d40428d8c1ff4415e407c2189038d6a2d401f02fd74f2415e40bfdd488f956a2d40d82ac1e2f0415e4079268f029f6a2d400f8c721fef415e4085059c4aab6a2d4045a56ceced415e40e01dcf1db36a2d4047414bb2e9415e40f0b61cf9cd6a2d40428de7d8e6415e40b78ebb52e06a2d40d236fe44e5415e402e104e55eb6a2d40974ffb52e4415e408e0d935ff56a2d40b599547ee3415e40836852af006b2d40f80780e0e0415e4029047289236b2d4029c302a9de415e40efd819f0436b2d4065de4f32de415e40048d3e8b4a6b2d40fa2af9d8dd415e4013149a7f4f6b2d40d10da892dc415e402a255f645d6b2d406c4bd356db415e40ad6818e3686b2d40f0a5f0a0d9415e4093793fc9786b2d401afa27b8d8415e400cf3d4d97f6b2d40ecf42801d6415e4003f3ebe2916b2d40e2e5e95cd1415e409fa40a90b26b2d40d79c28aecf415e40de0033dfc16b2d400d2950d5ce415e4068d94933cc6b2d40eab4c93ccd415e401a42846ee56b2d4098d3afbecb415e40e56ec61ffb6b2d405891d101c9415e40d41e40d01b6c2d40f9049a19c7415e40302c7fbe2d6c2d40e8fb04abc5415e4024873e0e396c2d40),
(30, 'Rockville Avenue', 'residential', 'yes', NULL, 'way/23213938', 0x000000000102000000030000000b42791f47425e404881aa76f2662d405395b6b846425e40bc3d0801f9662d401398f33144425e407039a80e03672d40),
(31, 'Talisay Street', 'service', NULL, NULL, 'way/23350359', 0x0000000001020000000900000003e154b5ee415e40c8e9904028682d40f99dcb79eb415e40e675c4211b682d404270a653e8415e40d6f95c120c682d4045cda156e2415e40b6018ef3ed672d40a1134207dd415e408e548440d3672d40d1555f02dc415e40c799cbb2cc672d409c4539e2da415e4031276893c3672d40432e8210da415e403b641415bb672d408decef11d6415e40f3db210f8e672d40),
(32, 'Bougainvilla Street', 'service', NULL, NULL, 'way/23649454', 0x00000000010200000005000000e4a08499b6415e4039a2d68fa8672d40bfa4e7ccac415e40a0ab0892d2672d40b0e99cfa9b415e40ee2affb517682d40ea37b81993415e4040a8e6cd3c682d406bbccf4c8b415e40e863e3665d682d40),
(33, 'Balete Street', 'service', NULL, NULL, 'way/23649455', 0x0000000001020000000a000000bfa4e7ccac415e40a0ab0892d2672d40cae77008b0415e40b34e4b62ff672d40b0822914b3415e40718b9e002f682d400cb89d6cb9415e40e679cb3049682d402244e856be415e40597be9375d682d4089809e61c5415e407f30f0dc7b682d40cbebd2d0d0415e40b6604e756d682d40b72f568ad3415e40f6e7476870682d40577d0970d5415e40662728ea71682d40cef28645d6415e40efc27bb372682d40),
(34, 'Bougainvilla Street', 'service', NULL, NULL, 'way/23649456', 0x00000000010200000013000000d7135d177e415e40d268177893682d40c621d1ba7c415e40285481a499682d4026169dd17b415e40740d33349e682d40091a33897a415e408731e9efa5682d4003d3c49679415e40655012b7af682d40f2f4a51279415e40f5053e50b8682d402d27fcad78415e400e57bdb2c1682d407bdb4c8578415e405cfd7d6bcc682d40c8ebc1a478415e40c7e4c3a2d8682d4063c4f47379415e4057276728ee682d404b2366f679415e409d60a4bcfb682d408008162c7a415e4062dba2cc06692d4027eec2207a415e401abc541113692d40dfe23cf779415e40209672631f692d401510a49c79415e4091ca5e002b692d400a54b59377415e40029eb47059692d406429ed6877415e403f55850662692d40e7abe46377415e40885eebf769692d4022ad8ca177415e4054466d2c72692d40),
(35, NULL, 'service', NULL, NULL, 'way/23927298', 0x0000000001020000001400000080b8ab5791415e402231e6536c692d4027288fb891415e40356090f469692d40f716201b92415e405b762dc665692d4001b969d894415e402fe708cf3a692d404e53156495415e4052c8df0731692d406c2409c295415e40930a197e26692d40a7f79edb95415e40eb88e87c1d692d401954c0e295415e401722f13c02692d40a2ad94af95415e408187b36cf7682d40c081244795415e403ecbf3e0ee682d408a2947b794415e405b5f24b4e5682d40fda8e1b691415e40b8fbc165ba682d4070e360808e415e405f84df3c8b682d406bbccf4c8b415e40e863e3665d682d40193d128a88415e407935e5af35682d40744694f686415e4020b017af1e682d40740179c086415e4089ad45b016682d40861046a286415e40e173cc1e0d682d407aef5ea486415e406655df54ff672d40fd71569f86415e406359d537d5672d40),
(36, 'Green Avenue', 'residential', NULL, NULL, 'way/24053292', 0x000000000102000000060000000951bea085425e40e9e62cfd95672d40205f420587425e40d262df0495672d406dc83f3388425e4019e7cafb93672d409494055d8c425e40a4c2d84290672d406ae4a9fd8c425e40f24bb32f8f672d40d5c5127b8d425e40c443183f8d672d40),
(37, 'Dizon Street', 'residential', NULL, NULL, 'way/24053296', 0x000000000102000000060000006974626aa6425e40bfdc820074672d40fe81cd94b1425e40d4a6a091be672d40d3212697b5425e40d4e06c29d6672d4072aebc3fb9425e40189238d0e8672d4011e2cad9bb425e40b9ee9c1cf4672d402b508bc1c3425e40d52137c30d682d40),
(38, 'Onyx Street', 'residential', NULL, NULL, 'way/24053297', 0x00000000010200000002000000ff209221c7425e40bde3141dc9652d40f19f6ea0c0425e40b58993fb1d662d40),
(39, 'Mocking Bird Street', 'residential', NULL, NULL, 'way/24053302', 0x00000000010200000003000000d15389577e425e405a3edc1f39672d4083ad6de580425e4042bfa552a2672d408eb74bd180425e406a32e36da5672d40),
(40, 'Rainbow Avenue', 'residential', NULL, NULL, 'way/24053304', 0x00000000010200000004000000c8282a768f425e40d04ab5aa806a2d406a238dc08e425e4076edc15a6b6a2d40f50137418a425e40778604e7e7692d409cbc6d4b89425e40b59e6ba9cd692d40),
(41, NULL, 'service', NULL, NULL, 'way/24053312', 0x0000000001020000000200000000a0d4a8d1425e40e6cf12bfbd662d40af71a202cc425e40b1b096f1a5662d40),
(42, 'Crystal Street', 'residential', 'yes', NULL, 'way/24053317', 0x00000000010200000002000000e31ea6d8ac425e40802260be06662d40a9328cbbc1425e400ff6813f57662d40),
(43, 'Saint Thaddeus Street', 'residential', 'no', NULL, 'way/24053320', 0x000000000102000000030000005f645d3700435e4064b95b4876672d40e16a532b02435e40db49e93ea5672d4046d1031f03435e4046de8321bc672d40),
(44, NULL, 'service', NULL, NULL, 'way/24053325', 0x0000000001020000000300000005943c8dea425e409aacf6555e672d401cb9c903ec425e40e66498c926672d405ea85725ec425e402adc97d821672d40),
(45, 'Yellow Bird Street', 'residential', NULL, NULL, 'way/24053326', 0x0000000001020000000200000010f16a146d425e408f577b33c5672d404c5aa7806a425e407e8b4e965a672d40),
(46, 'Saint Jude Street', 'residential', NULL, NULL, 'way/24053331', 0x0000000001020000000d0000000bad985beb425e40b537f8c264662d4057f95404ee425e4010eb8d5a61662d402bc7bf2af2425e405732b6c656662d40195932c7f2425e40577a6d3656662d40e98cde5ff3425e40a4e36a6457662d40dd0c37e0f3425e4055826a285a662d40f872fad5f7425e4087d1bd9877662d4027501fdcf8425e40738236397c662d40cd2f945dfa425e403a3defc682662d4050f40a55fb425e401a9cd20b88662d4085d61e51fc425e40ff6f36678e662d407237e38ffd425e4099ef856e9b662d40e31d3b03fe425e40cc947b26a0662d40),
(47, 'Carlos Street', 'tertiary', 'no', NULL, 'way/24053332', 0x0000000001020000000b000000742502d5bf425e400b91781e81682d40d269824dc2425e40635eec623f682d402b508bc1c3425e40d52137c30d682d403ccfe9c3c4425e40c0f68205e6672d4095174ff3c4425e4087dc0c37e0672d409b786231c5425e4007ce1951da672d409f292ad1c8425e4018c7ed3c96672d40934ac2cfc9425e40b13f3f4283672d40268bfb8fcc425e4061e52bdc4d672d40a33616b9cc425e409e7f16a64a672d408bc0fd25ce425e4082dceade2f672d40),
(48, 'Pink Flamingo Street', 'residential', 'yes', NULL, 'way/24053342', 0x00000000010200000002000000da25057179425e4005eff5ffbb672d40a0a3fa7376425e401a6437d840672d40),
(49, NULL, 'service', NULL, NULL, 'way/24053346', 0x000000000102000000030000009989d816d4425e4062eaf8799d662d409c14e63dce425e40391d120885662d408c9bbfaecb425e40a4ca8ba779662d40),
(50, NULL, 'residential', NULL, NULL, 'way/24053348', 0x000000000102000000050000006d4d5f749e425e4097fe25a94c692d4038dbdc989e425e409091a2844f692d40be0864c0a3425e401151f1248e692d409a01d30ea4425e4068a4ef7f91692d40d6308d70a4425e408a123ea594692d40),
(51, NULL, 'residential', NULL, NULL, 'way/24053353', 0x000000000102000000020000006a238dc08e425e4076edc15a6b6a2d40e3aab2ef8a425e4012651470746a2d40),
(52, 'Mahogany Street', 'residential', NULL, NULL, 'way/24053356', 0x00000000010200000006000000cb85cabf96425e403fb61b333f692d40ef30372996425e40f20467953e692d4038d89b1892425e406531564046692d4023d6879a8d425e403cbb213251692d40d7bd158989425e403136be405a692d4096a0754389425e40482a9d595c692d40),
(53, 'Saint Peter Street', 'residential', NULL, NULL, 'way/24053358', 0x000000000102000000090000008a288128f3425e4042fa3779db662d40b90bdea1f2425e409e3d3cf0d6662d40849cf7fff1425e4094731882d2662d4067ce9fdbf0425e401465259ccc662d40b0ff3a37ed425e40a6b8aaecbb662d40b17b3c3eeb425e402dcf83bbb3662d40a370e250e4425e406692472696662d4017a0c8eedd425e4097303fdc7a662d40ef5701bedb425e409cb0b3d771662d40),
(54, 'Guijo Street', 'residential', NULL, NULL, 'way/24053363', 0x0000000001020000000300000030d5cc5a8a425e401d3ee94482692d401acae42f88425e4030d230218b692d40b521b53f86425e40599f1793a3692d40),
(55, 'Kalinisan Street', 'residential', NULL, NULL, 'way/24053384', 0x000000000102000000030000006c02b111ad425e4000a6b1625d692d40ac5ed960bc425e40fae879dc5c692d40799274cde4425e40a1759ec25b692d40),
(56, 'Amethyst Street', 'residential', NULL, NULL, 'way/24053400', 0x00000000010200000005000000c138b874cc425e40d459773de2652d403a330bfec8425e401eda6c510b662d40dcda1dadc5425e406f3777aa32662d40601e32e5c3425e4018f66a3645662d40a9328cbbc1425e400ff6813f57662d40),
(57, 'Jade Street', 'residential', NULL, NULL, 'way/24053401', 0x00000000010200000004000000de9d6b4e94425e406743a3e0ce662d4076ff58888e425e4005961238c8662d40764710f88d425e40713898f2c6662d400578c1968d425e40ef31a2fec4662d40),
(58, 'Saint Philip Street', 'residential', NULL, NULL, 'way/24053404', 0x0000000001020000000f000000e824a5eae8425e4010dbccd71b672d40c41d1439e9425e407e05c47f15672d400036c588e9425e40da907f6610672d40b2c68fe7e9425e402f3f26080d672d400900e9f6ed425e40bd152e50f7662d40139f967af1425e40ea7b687ae4662d4060394206f2425e4051f1248ee1662d408a288128f3425e4042fa3779db662d4083aa2c65f4425e4093533bc3d4662d40703903c8f5425e4008139040cd662d4085f0c39cfb425e405405fe4bad662d40e31d3b03fe425e40cc947b26a0662d4078955a94fe425e404419051c9d662d4053a2db010d435e4019a3bfe14f662d405109997510435e4010dc92663d662d40),
(59, 'Lime Street', 'residential', NULL, NULL, 'way/24053405', 0x00000000010200000009000000794b283394425e40c2042450b3662d4061962cdd93425e40464bd4c1b0662d40c702154493425e40188bf040ae662d405fc65e398c425e40d8e610829f662d40a9424d3e87425e4084f3a96395662d4003ab8f2c85425e409e4720b990662d402d2dd96784425e40e07e654a90662d4069030bbb83425e403ff72f5a91662d407583b23a83425e402b80ce4994662d40),
(60, 'Sapphire Street', 'residential', 'yes', NULL, 'way/24053424', 0x000000000102000000090000009f967a71bd425e405641b1ba7a662d40f3e2c457bb425e40133d3abf72662d40379c4363b7425e4050ba3ebd63662d4002dfc897ab425e40e413b2f336662d404f96b5a8aa425e408146448c32662d40fcf61a27aa425e40f49d04db2d662d40f0a72105aa425e40381504ea28662d4008180225aa425e4059b620a523662d404f96b5a8aa425e4092431f871c662d40),
(61, 'Saint Thaddeus Street', 'residential', 'no', NULL, 'way/24053439', 0x0000000001020000000e00000053a2db010d435e4019a3bfe14f662d40bc2f1d2911435e406c4084b872662d406ea9de7511435e40114537b176662d40b0986c9711435e40fd851e317a662d40c7f143a511435e403ca583f57f662d405062218411435e40eb93371b86662d40fd9474de10435e404b66ab819c662d40e022410210435e40b252f7b7ba662d40694e03ab0f435e40e3ffe961c3662d40c9e30e400f435e406ef8dd74cb662d40edbc8dcd0e435e404dc752dad1662d408effa7870d435e4040ba7dfbdf662d400c2a60f10a435e409d4c37e4fa662d40b7d100de02435e40e7db27ec47672d40),
(62, 'Aries Street', 'residential', NULL, NULL, 'way/24053447', 0x00000000010200000002000000f446f7bd97425e40ea0e18daef672d401a80b2ce9d425e40f39771aebc672d40),
(63, 'Gemini Street', 'residential', NULL, NULL, 'way/24053448', 0x000000000102000000120000003a9160aa99425e407157af22a3672d409f28bffb99425e4023168ca5a3672d402e3fcb4e9a425e40768478c9a4672d4052fea4909a425e4093c5fd47a6672d402d67a5ff9b425e40e2fb2ce0af672d401a80b2ce9d425e40f39771aebc672d4062156f649e425e407a8379d9c0672d40f68c8ef59e425e40c5cc9948c4672d40209672639f425e40cab1ab7fc6672d40ba1281ea9f425e400b11cbc1c7672d40de2d7f74a0425e4040aec387c8672d4078aa8dfba0425e40ab7823f3c8672d40d7530669a1425e40341477bcc9672d40c58954bda1425e40928c41ccca672d40b3bfa211a2425e401a9826b6cc672d4000fe2955a2425e404f5df92ccf672d406b836e8aa2425e403b2e4f8cd1672d406b69c93ea3425e40a2c0f16bda672d40),
(64, 'Rainbow Avenue', 'residential', NULL, NULL, 'way/24053451', 0x00000000010200000009000000616b5b39a0425e40cd4c7a2986692d409f28bffb99425e408c7ad2d391692d404e3c0c5295425e40767bffd599692d40c8afc4a890425e40d14b7b39a2692d407db1f7e28b425e40f0e9a001ab692d404eebdbee8a425e4017f549eeb0692d40548039c489425e40a49295babf692d402ba5677a89425e4047776bf4c5692d409cbc6d4b89425e40b59e6ba9cd692d40),
(65, 'Camia Street', 'residential', NULL, NULL, 'way/24053457', 0x00000000010200000005000000fe7e315bb2425e403d201a27cf662d40eae74d45aa425e40188bf040ae662d40a49a481fa9425e40026f3777aa662d407a7df7d8a7425e4057d526a9a7662d403d1faf51a0425e40b4c876be9f662d40),
(66, NULL, 'residential', NULL, NULL, 'way/24053469', 0x00000000010200000004000000e3aab2ef8a425e4012651470746a2d40338b506c85425e40671998cbfc692d402753605c85425e408c9fc6bdf9692d400f11926085425e40298aa1e6f5692d40),
(67, 'Kamagong Street', 'residential', NULL, NULL, 'way/24053475', 0x0000000001020000000300000032d3ac2292425e40eba3f89dcb692d40c8afc4a890425e40d14b7b39a2692d4023d6879a8d425e403cbb213251692d40),
(68, 'Green Peasant Street', 'residential', 'yes', NULL, 'way/24053476', 0x000000000102000000030000006170cd1d7d425e408eb51a6db0672d40eacc3d247c425e4096a3117d88672d403354c5547a425e409f3a56293d672d40),
(69, 'Topaz Street', 'residential', NULL, NULL, 'way/24053479', 0x0000000001020000000600000001028c1dc3425e406215ca1d91662d40ff1df6e7c7425e40a6ed5f5969662d402e9c5a6cc9425e403044f3a55c662d40b6eff6c5ca425e40669c2bef4f662d408ce0dae4cb425e40fc44549742662d40421fd1a9d0425e4005d1a45e01662d40),
(70, 'Saint Anthony Street', 'residential', NULL, NULL, 'way/24053482', 0x00000000010200000003000000137c783be7425e4004dd0319a6672d40cb564dc6e7425e4033f389e18f672d405393e00de9425e4018a600625c672d40),
(71, 'Carlos Extension', 'residential', NULL, NULL, 'way/24053483', 0x00000000010200000004000000f038a000e5425e40331b649291672d4093e34ee9e0425e40d16dd3e98a672d40821fd5b0df425e401acae42f88672d40268bfb8fcc425e4061e52bdc4d672d40),
(72, NULL, 'service', NULL, NULL, 'way/24053485', 0x000000000102000000030000009c14e63dce425e40391d120885662d40af71a202cc425e40b1b096f1a5662d408de9ae91c9425e402d99be32ca662d40),
(73, NULL, 'residential', NULL, NULL, 'way/24053491', 0x00000000010200000009000000ce1ec3be78425e40390202e7d6692d406114a9d57c425e400b6def09c8692d400137e6d07d425e403b25d698c6692d404dc8bdaf80425e40a17ab5edc5692d409cbc6d4b89425e40b59e6ba9cd692d407cabbf6f8d425e40f37519fed3692d40b028db7690425e40152c1f93d6692d40446cb07092425e406ee7b11cd7692d404f6dbaaf94425e401ba19fa9d7692d40),
(74, 'Metro Avenue', 'residential', NULL, NULL, 'way/24053492', 0x000000000102000000110000007583b23a83425e402b80ce4994662d409f7829d082425e40b193b0259a662d4064a593b682425e40e318c91ea1662d404c7acecc82425e40c8a4750aa8662d40fd8e972485425e40c87dab75e2662d40214bd52c86425e402f6af7ab00672d405c1e6b4686425e40683cb60a07672d400920104386425e405165bdbd10672d409e9acb0d86425e40d215116a2b672d40331587d885425e404b81bba24a672d400f9bc8cc85425e40f422c96251672d40a42c8da985425e40486de2e47e672d400951bea085425e40e9e62cfd95672d406ea301bc85425e40af8108cc9e672d40bbe188ff85425e402c088ac4a9672d40afeeb32586425e40ee4dc23baf672d4038a4ac3a86425e4028d0cc38b2672d40),
(75, 'White Duck', 'residential', NULL, NULL, 'way/24053494', 0x0000000001020000000a0000006cde82b666425e40e445cb2665672d403cb60a0767425e4014feb1b563672d404c5aa7806a425e407e8b4e965a672d4068a961646e425e40728c648f50672d40a8a0ec7772425e4029a3db5c46672d40a0a3fa7376425e401a6437d840672d403354c5547a425e409f3a56293d672d40d24554f27b425e400520a45d3b672d40d15389577e425e405a3edc1f39672d40bec51e3581425e40ea8e6a7d36672d40),
(76, 'Red Macau Street', 'residential', NULL, NULL, 'way/24053500', 0x00000000010200000002000000a8a0ec7772425e4029a3db5c46672d40c4c4307175425e40bae2981bc2672d40),
(77, NULL, 'residential', NULL, NULL, 'way/24053501', 0x00000000010200000005000000d4f60a66a7425e40d600a5a146692d407b0aca7ea7425e404bdddfea4a692d4021d96d61a7425e40480db78d50692d404c8c65faa5425e4096c5692d71692d40d6308d70a4425e408a123ea594692d40),
(78, 'Taurus Street', 'residential', NULL, NULL, 'way/24053504', 0x0000000001020000000d000000f446f7bd97425e40ea0e18daef672d401d67e43d98425e408451a456f3672d40cac4ad8298425e40dc7cc800f5672d40b2f50ce198425e4034a8ecaaf6672d40f95cb75299425e40feea1626f8672d40586254089a425e403f027ff8f9672d405776c1e09a425e4043e7902ffc672d40ecede0719b425e40a217a4cffd672d401b13bde79b425e406c5ace4aff672d400f7c0c569c425e40be8003ff00682d40b602f9c89c425e406f67ba3203682d408048bf7d9d425e404494e5da06682d40fd21ecca9d425e40f6c2537e08682d40),
(79, 'Saint Andrew Street', 'residential', NULL, NULL, 'way/24053519', 0x00000000010200000006000000b0ff3a37ed425e40a6b8aaecbb662d40a68e9fd7e9425e401e77007ad0662d4041fadcbfe8425e400a70308ad4662d4018f4948be7425e4010e5b0a0d5662d406c6b555ce6425e4040e54e9fd3662d402030c50bd8425e40db8b683ba6662d40),
(80, 'Myrtle Street', 'residential', NULL, NULL, 'way/24053523', 0x000000000102000000020000007480bb4791425e408ea2186a5e672d400f9bc8cc85425e40f422c96251672d40),
(81, 'Acacia Street', 'residential', NULL, NULL, 'way/24053532', 0x00000000010200000003000000e20cb4f196425e40bd7383fcc7692d404e3c0c5295425e40767bffd599692d4038d89b1892425e406531564046692d40),
(82, 'Prada Street', 'residential', NULL, NULL, 'way/24053545', 0x000000000102000000120000007f880d16ce425e405da79196ca672d40d8d30e7fcd425e40a350604bd9672d40982fd406cc425e40a2cfec5ffe672d40c2418c21ca425e40540262122e682d40abd1ab01ca425e40ed44ee8e31682d4005094092c8425e40de51088959682d4070044e5bc8425e40a55478865f682d4076c4211bc8425e4078190f0066682d401763601dc7425e404e582c8f7f682d40359078c3c7425e40c6cecaac94682d405e995c31c8425e4077d267aca2682d405e3a9cafc8425e4079043752b6682d40993b44edc8425e40f6b292fbc2682d408d1a5defc8425e407651f4c0c7682d40ab7823f3c8425e407e6bcc90cf682d40f33e8ee6c8425e4093af5f0bd5682d400b9b012ec8425e405c71169bfb682d40b76e9406c8425e40cb20883dfe682d40),
(83, 'Taurus Street', 'residential', NULL, NULL, 'way/24053547', 0x0000000001020000000f000000623da4ce92425e401c9029c4c8672d40b53bffd192425e40069c4aabc6672d40dfd1b5e592425e403ca1d79fc4672d4032fe220d93425e40e40522d5c1672d406dffca4a93425e40e66db603bf672d40cc913aa693425e40ff31be79bb672d405ba846f993425e40247035fcb8672d402b97d75b94425e409dac0782b6672d40b4d606dd94425e4080fbf0e2b3672d40cbb6781d96425e40e2d3522fae672d405923714598425e40f35da516a5672d403b38d89b98425e40d6d46828a4672d40e190b2ea98425e40ac414e4ea3672d4088e98c3999425e40366d10f7a2672d403a9160aa99425e407157af22a3672d40),
(84, 'Dahlia Street', 'residential', NULL, NULL, 'way/24053550', 0x0000000001020000000b000000e4a9fd8cc1425e4048ed3488c5662d40b1d35977bd425e4097097547b5662d40f63c2421b6425e402263ff869a662d40e90c8cbcac425e4016026f3777662d400da1ef13ac425e40e889422674662d40cc3e3498ab425e4098a3c7ef6d662d40fc389a23ab425e403139ffc066662d40cdb79965aa425e40ceb348c961662d40bb664d87a9425e409916500361662d4024928daca1425e404822eaf472662d408a439149a1425e4059c922a875662d40),
(85, 'Mint Street', 'residential', NULL, NULL, 'way/24053553', 0x00000000010200000002000000dd94f25a89425e409c621faee6662d40a9424d3e87425e4084f3a96395662d40),
(86, 'Lime Street', 'residential', NULL, NULL, 'way/24053566', 0x0000000001020000000500000055a3570394425e40d721ed35f3662d40de9d6b4e94425e406743a3e0ce662d401f8df96f94425e40a0fb7266bb662d40ba51bf6694425e400d068d4fb7662d40794b283394425e40c2042450b3662d40),
(87, 'Pilaring Street', 'residential', NULL, NULL, 'way/24053574', 0x00000000010200000004000000b263c856bc425e40922232ace2692d40eb7afda4b5425e40f12a6b9be2692d40a0826852af425e40e5208dafe2692d400fc70446a8425e402d150ac7e2692d40),
(88, 'Pisces Street', 'residential', NULL, NULL, 'way/24053594', 0x000000000102000000020000006b69c93ea3425e40a2c0f16bda672d40fd21ecca9d425e40f6c2537e08682d40),
(89, 'Silver Gull Street', 'residential', NULL, NULL, 'way/24053598', 0x000000000102000000070000006cde82b666425e40e445cb2665672d40c0c5d4a766425e40d086b2a668672d403c88f8e266425e403689e6a672672d40c5f5398867425e400b3895568d672d401290e51368425e40695abd1ea7672d40f4d25e8e68425e4016269d92bd672d40ca98ccc268425e408cdafd2ac0672d40),
(90, 'Saint Simon Street', 'residential', NULL, NULL, 'way/24053600', 0x0000000001020000000d00000017da9486f5425e4085ac133c2a672d403b6b5ca4f5425e40f46679c322672d402f8f90dcf5425e40d91df7521d672d4070f14b58f6425e404770c8ab18672d40ab4e18def6425e40f521b94615672d406b85443500435e4026aebe15e4662d40e22b706800435e401b344f09e3662d40778192020b435e4031bf89d7ab662d40ed94b31c0d435e405a35bee5a0662d405ec026c60d435e409787f13f9e662d40464daa6c0e435e40925a28999c662d40b7bd384c0f435e405dbd2fd39b662d40fd9474de10435e404b66ab819c662d40),
(91, 'Waling Waling Street', 'residential', NULL, NULL, 'way/24053615', 0x0000000001020000000500000000a2aa53af425e40ebf2f79c05672d40518b1c7da7425e40ba0b395be5662d4087d2286ea6425e4003b00111e2662d40e165e146a5425e40a00a6e5adf662d40ccae20729f425e4079477cddd8662d40),
(92, 'Rosal Street', 'residential', NULL, NULL, 'way/24053618', 0x000000000102000000070000002de68ccdb3425e40eb6a97db62672d40c806770cb4425e40b1581eff60672d402138d329b4425e404766e4e25e672d408450943ab7425e403b014d840d672d409c1c99a2b7425e40c25fddc204672d401f40d01bb8425e40ba8dbc62fc662d40b1d35977bd425e4097097547b5662d40),
(93, 'Saint James Street', 'residential', NULL, NULL, 'way/24053621', 0x00000000010200000003000000c5f70f33c5425e4001fcae63b7662d408de9ae91c9425e402d99be32ca662d404af14cc3cb425e4011058e5fd3662d40),
(94, 'A. Ramirez Street', 'residential', NULL, NULL, 'way/24053655', 0x0000000001020000000f0000001afa27b8d8415e400cf3d4d97f6b2d40e2d4bd04dd415e4072dc291dac6b2d40d00a0c59dd415e4042dc8b1eae6b2d40a0f99cbbdd415e4089409a56af6b2d40a09adc39de415e40410466cfaf6b2d40dbf7a8bfde415e4047510c35af6b2d40aa7ea5f3e1415e40dae15410a86b2d40bb703150e3415e402e008dd2a56b2d4014121f8ee4415e40be78f5e0a46b2d4067c526e8e5415e400b2aaa7ea56b2d406047d224e7415e40b04e3a36a76b2d40f1304855ee415e4083e8ff0bba6b2d4062a1d634ef415e40d00946cabb6b2d4020c6b5ebef415e408ed20039bc6b2d4079c663abf0415e40edda3928bc6b2d40),
(95, 'Emerald Street', 'residential', NULL, NULL, 'way/24053656', 0x00000000010200000017000000e003858b26425e4083c9e8dbdd6a2d4082774da324425e4046f5317ac96a2d404d501e7123425e405637cdf1c06a2d400c08084122425e400b7e1b62bc6a2d40f527960021425e407d6d4782ba6a2d4014758b651f425e403579ca6aba6a2d40a951a3eb1d425e4088e7b68ebb6a2d405d024b091c425e4068d608b3bf6a2d4088e6f0ff19425e401398f331c46a2d40b2857bc017425e40a7f56d77c56a2d400731862815425e40dd6a8c8cc46a2d40a318c51712425e4067fee263c16a2d40f96de3aa0d425e40b2c288d8bb6a2d407ebacb8f09425e40c054d8b1b66a2d4099e6673403425e4010d6b5acb16a2d4046787b1002425e4057f20c75b36a2d40ee63607800425e40e2c226d7b96a2d4018456a35ff415e4090018f5ec36a2d40a96a82a8fb415e40044070f0e06a2d4045aee5dff8415e40a5710399f86a2d4088050830f6415e40c30c326e0f6b2d40b73874c4eb415e4061d74004666b2d4095719d90e7415e406056cd188b6b2d40),
(96, 'Pink Street', 'residential', NULL, NULL, 'way/24053658', 0x0000000001020000001800000018a2f9522e425e40dffdf15eb56a2d40e003858b26425e4083c9e8dbdd6a2d400c361a6522425e4077d1fcd6f36a2d40e4326e6a20425e40fc349314fd6a2d4014eb54f91e425e40814875f0026b2d403882548a1d425e40022f8e25076b2d4080c1244b1c425e400d6146c2086b2d40168733bf1a425e406d697fb1086b2d402383dc4518425e4062c735f4056b2d40eb85a7fc10425e402bcd9ce4fd6a2d4073cd2e2908425e40fa6761aaf46a2d4003ed0e2906425e40018d2d5ff26a2d405176e91505425e4037ba9404f26a2d40456fa76304425e40241b5943f36a2d40abc486b803425e40db76908df66a2d403ba2e7bb00425e40f1845e7f126b2d4012e456f7fe415e4060c1470e226b2d40392e3e60f9415e4072d41bff4f6b2d4081c93269f8415e40aeb3c6455a6b2d40044fc69df7415e405bd2510e666b2d40b1af2b1cf7415e40e462b1f2706b2d40e721aef7f6415e4017505e1a756b2d4094f540d0f6415e40bcc4a2337a6b2d40888f3e9cf6415e401eaff6668a6b2d40),
(97, 'Rainbow Street', 'residential', NULL, NULL, 'way/24053659', 0x0000000001020000000b0000004e6f35a1ff415e4042322e66956b2d40535a7f4b00425e40f88667ae786b2d40eebf84c000425e409214a28d6d6b2d40d0752b9501425e40388cdd99646b2d40fd2c3b6906425e40e7be41203c6b2d40509ec3c606425e40cce550d0376b2d40735d9d0807425e4016623fd5326b2d40c7890a3007425e40b9292f432d6b2d4073cd2e2908425e40fa6761aaf46a2d407ebacb8f09425e40c054d8b1b66a2d40a74de6690a425e40f2d5e99b8f6a2d40),
(98, 'Blue Street', 'residential', NULL, NULL, 'way/24053660', 0x00000000010200000007000000168733bf1a425e406d697fb1086b2d40d53b81551a425e40ad026b8b216b2d40b1c1c2491a425e40c60b337e2b6b2d4004ee2f711a425e408b16a06d356b2d40460bd0b61a425e4034e087de3d6b2d40bcabc3761c425e402ccab61d646b2d40e4c578831e425e40eb6e9eea906b2d40),
(99, 'Ivory Street', 'residential', NULL, NULL, 'way/24053661', 0x0000000001020000000700000021b30ea210425e408e684cd2466b2d402da3474211425e40d7998c74506b2d4044108c2812425e403c7ce3b55c6b2d404f84c3c114425e40285c3409836b2d40a120c20916425e401717a29e996b2d407d8c5eb216425e4099caec3da66b2d40530a157717425e40df73bbf2b46b2d40),
(100, NULL, 'residential', NULL, NULL, 'way/24053662', 0x0000000001020000000300000035ae241ef5415e40f9bd4d7ff66b2d40e74c7f9bea415e40feb04a8ee06b2d4096181582e6415e404a253ca1d76b2d40),
(101, NULL, 'residential', NULL, NULL, 'way/24053663', 0x00000000010200000009000000e74c7f9bea415e40feb04a8ee06b2d40a0e238f0ea415e40dd1a22b8db6b2d4034fe3339eb415e40267733fed86b2d4093a7aca6eb415e401b457b61d76b2d40221add41ec415e406fd34444d66b2d40f09aa102f1415e40bec4b35fd26b2d40acf82b09f5415e4007697c15cf6b2d408808a469f5415e40ba275998cf6b2d40ed9f02bbf5415e4012537d42d16b2d40),
(102, 'Libra Street', 'residential', NULL, NULL, 'way/24053664', 0x0000000001020000000a000000e5df1dcf1d425e40a6eb2ef598692d4029266f8019425e4084c5973f95692d40305173a815425e403fc91d3691692d4037e96cb713425e407bd399208f692d40df75919d12425e40c4e7f3f68c692d40afc67ebb11425e40d2e9d4f088692d405781b5c510425e403e6480fa85692d40283163650f425e40ab96749483692d400b9755d80c425e40715c210780692d405494a69c0a425e409ce73eef7c692d40),
(103, NULL, 'service', NULL, NULL, 'way/24053665', 0x000000000102000000020000004d0a3dac01425e40f8a6e9b3036a2d402c97321507425e409e83c2fb056a2d40),
(104, 'Virgo Street', 'residential', NULL, NULL, 'way/24053666', 0x000000000102000000060000008d976e1203425e40ca726d03d2692d408b12995e07425e40d9f9c8f7d6692d40a6b4a3dd0d425e402950d54ede692d402d2d7eae11425e401b063de5e2692d40034f102b12425e404529c69ee2692d4068fd778e12425e40d4a12eade1692d40),
(105, 'Leo Street', 'residential', NULL, NULL, 'way/24053667', 0x00000000010200000005000000283163650f425e40ab96749483692d406a0c84ae0e425e40f3542c239a692d40ff2a1b310e425e40d6952aacaf692d40edbf29070e425e406d8d08c6c1692d40a6b4a3dd0d425e402950d54ede692d40),
(106, 'Taurus Street', 'residential', NULL, NULL, 'way/24053668', 0x0000000001020000000200000093bc84541b425e4026b6717acd692d4079c1f1c613425e4088d68a36c7692d40),
(107, 'Diamond Avenue', 'residential', NULL, NULL, 'way/24053669', 0x0000000001020000001400000090cd9f8037425e40bde0d39cbc682d40933e085c32425e40c73a66eabf682d401138126830425e40089a852cc1682d40835550ac2e425e406e371cf1bf682d40f7f4c76a29425e4052167431bc682d402a070ec322425e40633035f8b1682d40d61643de17425e40b05f668e9b682d40c65e398c13425e40c7a6f0fb92682d4069345e5f10425e4046c0d7c68e682d4070b54e5c0e425e400bae5eea8c682d407d8049850c425e40e1421ec18d682d4054ae4be809425e40d268177893682d40e5a2b5fd06425e40f12e17f19d682d40f847293204425e406f4507c9a7682d40b7baf7cb02425e40e1e18794b0682d40d0bde20401425e409d3fb7e1c1682d400664af77ff415e403af4cc81d4682d40f041be3afd415e4008e34cb8fc682d400ac446b4f8415e40f1f67bbd56692d4075633035f8415e40d4d2dc0a61692d40),
(108, 'Amethyst Street', 'residential', NULL, NULL, 'way/24053670', 0x00000000010200000010000000063708292e425e4062235a3c06692d40c21d030d11425e40cd14843ccc682d404b636a0110425e40d4a9e111cb682d4099a729b80e425e40c89f0326cb682d404dfcac8d0c425e40086fb488cd682d4090aff3250a425e407b53ecc3d5682d40cce7813408425e4052256f25e0682d40624ed02607425e406b76ee87e9682d4050e67a3606425e405237610cf6682d40356c4a6801425e40eb7e04b463692d405ff12fddff415e40fc7fe6bd7b692d4012859675ff415e409412279c82692d402b5d0bc4fc415e406a3b5c61b0692d40babbce86fc415e407e175badb8692d40d84a43e8fb415e40398485eeed692d40d30039bcfb415e40e13f82870e6a2d40),
(109, 'Jade Street', 'residential', NULL, NULL, 'way/24053671', 0x0000000001020000000400000060e1c9132d425e40908d9b7521692d40063708292e425e4062235a3c06692d40f96b0d0030425e40495e42aacd682d401138126830425e40089a852cc1682d40),
(110, 'Gamma Street', 'residential', NULL, NULL, 'way/24053672', 0x00000000010200000009000000bc9c6dc905425e4011678f615f682d4089624dc00a425e403a1389f83d682d40c94b48b519425e402af7a7f9cf672d40b7f4c3631a425e40b5d2b540cc672d40ec91bc291b425e405def4806ca672d40bc0a84f81b425e40f26ca00ac9672d40153944dc1c425e40e662c21ec9672d400e76d4e21d425e40b6aadb8fca672d40ce925bee27425e40b21f73afdd672d40),
(111, 'Beta Street', 'residential', NULL, NULL, 'way/24053673', 0x0000000001020000000400000085da25602a425e40f3a55c86a4672d40ce925bee27425e40b21f73afdd672d40ff25040624425e40d188e30a39682d4059fed71423425e40d7c79e9850682d40),
(112, 'Omicron Street', 'residential', NULL, NULL, 'way/24053674', 0x0000000001020000000d000000ff25040624425e40d188e30a39682d40ce4763fe1b425e402e1796e425682d40575fb8ce1a425e40e2f54f2624682d4058ef26ae19425e40293284ad23682d409a40118b18425e405882d60d25682d408f81864817425e403ee6a8482a682d4084abf2f315425e4099b624ac32682d407962314514425e40d0b0bdbb3a682d405cdc909012425e400f18daef3f682d40e0ac776e10425e40c0266bd443682d404636a15a0e425e4078a27fdd44682d408e8f16670c425e4002a667d542682d4089624dc00a425e403a1389f83d682d40),
(113, 'Topaz Street', 'residential', NULL, NULL, 'way/24053675', 0x0000000001020000000300000081ee2653e0415e4062e7b7f990692d4043d83a82e5415e40ade52906a3692d40d84a43e8fb415e40398485eeed692d40),
(114, 'Zircon Street', 'residential', NULL, NULL, 'way/24053676', 0x00000000010200000004000000392861a6ed415e40e7c3b30419692d409f24b8eceb415e407316516e36692d40002258b0e8415e409ec25b316d692d4043d83a82e5415e40ade52906a3692d40),
(115, 'Saphire Street', 'residential', NULL, NULL, 'way/24053677', 0x00000000010200000002000000002258b0e8415e409ec25b316d692d402b5d0bc4fc415e406a3b5c61b0692d40),
(116, 'Ruby Street', 'residential', NULL, NULL, 'way/24053678', 0x000000000102000000050000005ff12fddff415e40fc7fe6bd7b692d4075633035f8415e40d4d2dc0a61692d4006ce63def4415e40337678be55692d409f24b8eceb415e407316516e36692d40cc79c6bee4415e408c80af8d1d692d40),
(117, 'Acme Road', 'residential', NULL, NULL, 'way/24053680', 0x0000000001020000000f000000bf9f75e8cf415e40b5c766a2636a2d408f8e064bd0415e4048bd4cb9676a2d40b2e8e797d2415e40d0926c1a806a2d404c906c09d4415e40bdf039668f6a2d40aa78c839d6415e40f85c5c99a66a2d40b6204a6ad7415e40b2a5a20cb06a2d40aecd6b91d9415e4011cbc1c7bb6a2d403161342bdb415e4013286211c36a2d4019929389db415e40b874cc79c66a2d406cbe00b1db415e40274c18cdca6a2d4019c0a5addb415e403493b943d46a2d40e95212c8db415e4055e12aaad96a2d409bccd314dc415e400badf314de6a2d404710f80ddd415e4009ddcab7e36a2d40b599547ee3415e40836852af006b2d40),
(118, NULL, 'residential', NULL, NULL, 'way/24053681', 0x00000000010200000006000000299da3e9c7415e40034f6be4046b2d4026eabb11cc415e40116e32aa0c6b2d403a50f1c9d4415e40c7c672011e6b2d400fb40243d6415e40e2c73d02246b2d40494a7a18da415e40419ab1683a6b2d40fa2af9d8dd415e4013149a7f4f6b2d40),
(119, 'Emerald Street', 'residential', NULL, NULL, 'way/24053682', 0x000000000102000000040000007398d4754d425e4095336f302f672d406fd39ffd48425e4004a50d2cec662d406e4b89c940425e404518f5ff60662d40278b56493f425e40299da3e947662d40),
(120, 'Silver Street', 'residential', NULL, NULL, 'way/24053683', 0x000000000102000000140000001aec979963425e40c7c672011e672d40b49080d165425e40dced1fb017672d403c54ae4b68425e40e69a5d5210672d40cac0a6736a425e4060cf32e609672d408dfb45bf6c425e4016365e1503672d4015527e526d425e40b24813ef00672d404baa5be26d425e40d2110a5bfd662d40dfc5562b6e425e40d9c644eff9662d40f8f653886c425e4046ea3d95d3662d404c4002356b425e400c811255ae662d400b3d073b6a425e40bbf8365893662d402f302b1469425e405a6b836e8a662d408379d9c067425e40e5d6ff9485662d403e38448163425e40a21a40097d662d408fed6b135d425e40d70ae42373662d40da8cd31055425e40c526e8e566662d407c5cc07053425e4018dd8b7967662d406b2519de51425e4077c5e7a969662d40851d6beb4c425e40cea55df179662d406e6b0bcf4b425e404fd42d967d662d40),
(121, 'Diamond Street', 'residential', NULL, NULL, 'way/24053684', 0x000000000102000000040000004c8a8f4f48425e402a4def8744662d4010864bd848425e40a9f34d3f4d662d406e6b0bcf4b425e404fd42d967d662d40e9bf626850425e4023cca3d1d3662d40),
(122, 'West Berkeley Street', 'residential', NULL, NULL, 'way/24053743', 0x000000000102000000020000009aaecc003c415e4021c8e64fc06b2d4002e66be058415e4041333e82d16b2d40),
(123, 'East Berkely Street', 'tertiary', NULL, NULL, 'way/24053744', 0x000000000102000000180000005c5f7f6d58415e40ff0af4e4f56b2d40867a55c26e415e406045fc79096c2d4004d9fc0978415e408c35b79d116c2d40ff6f912081415e405e2228c8196c2d401045dcf783415e402ddad2591c6c2d403781334289415e405475ea25216c2d40fe1076e58e415e406a49ec7f256c2d4033d9e49590415e4064fc451a266c2d40d32934b591415e405e87c503256c2d40e5a892b792415e400cf1fe2e226c2d407f98ce9893415e404a1b58d81d6c2d406d58535994415e40d01154e8176c2d40b3cd323097415e40c5ed8623fe6b2d40ca0c65f297415e4004f0051cf86b2d404d75b7a198415e40361081d9f36b2d40db711ea999415e400223d4b1ef6b2d4081de65d09a415e40f20b0adeeb6b2d40ada64643a1415e406161d229d96b2d40a578a6e1a5415e40b5d2b540cc6b2d404904f40cab415e4093b71270be6b2d40c51c041dad415e40bf1a56a7b96b2d405344e10eaf415e40677fa0dcb66b2d40bedd921cb0415e406d3cd862b76b2d40bd1f1219b1415e406cac6983b86b2d40),
(124, 'Calugas Street', 'residential', NULL, NULL, 'way/24053745', 0x000000000102000000020000002f2f6585c7415e4017ab178dc66b2d405b61fa5ec3415e4049ec7f25fc6b2d40),
(125, NULL, 'service', NULL, NULL, 'way/24053746', 0x0000000001020000000d000000a8943204db415e4008a5d4ca296e2d407989fbd9d9415e409deb45feaa6d2d400287ab5ed9415e40d03989528c6d2d401a3f43eed8415e40edcdb925836d2d4044ef9e4dd8415e40e46b2ae67b6d2d400a70308ad4415e4086014bae626d2d40586fd40ad3415e40ef2653605c6d2d40e846fd9ad1415e40688302a5576d2d40e3eb21d0cf415e4081b79b3b556d2d4076db2a2dc8415e40439836774f6d2d404d310741c7415e4078c59d1c4f6d2d40599aa5aec6415e40b58762974d6d2d40a1d9756fc5415e409a869796476d2d40),
(126, NULL, 'service', NULL, NULL, 'way/24053748', 0x0000000001020000000c000000efb902c0e7415e409b68a1aeff6c2d40a94423e9e4415e40707ced99256d2d40e4a48ba8e4415e406df47bac2a6d2d40ea7b687ae4415e40769ec25b316d2d4056a58867e4415e40ad985b6b396d2d406db9443fe4415e40e6a7dd54496d2d405649641fe4415e4096de48ea4e6d2d400e10ccd1e3415e40bd7960b6536d2d400591fb0cde415e404229b5728a6d2d40bfb9bf7adc415e40f47409e2976d2d406c06b820db415e4077483140a26d2d407989fbd9d9415e409deb45feaa6d2d40),
(127, 'Saint Peter Street', 'residential', NULL, NULL, 'way/24053749', 0x0000000001020000000a000000b6bfb33d7a415e4087d1bd98776e2d4037644d767d415e40923534af346e2d40a2fdfe837e415e401abf95911f6e2d40d19508547f415e40b29c84d2176e2d40b8f1dd9c80415e40c7eb0b32136e2d408bcae1ee87415e401ebd8685ff6d2d402e98ae168e415e4044fef4faee6d2d405de2c80391415e40a239fc7fe66d2d40c1035ec191415e4003f2800de36d2d40d942908392415e40c2da183be16d2d40),
(128, 'Saint Andrew Street', 'residential', NULL, NULL, 'way/24053750', 0x0000000001020000001a000000207efe7b70415e403b55be67246e2d401aec3ce070415e40c2a563ce336e2d400795b88e71415e40f03a76ab426e2d40fb9e477b72415e40c0e72c584f6e2d40c59c56c073415e40ea6f534d5a6e2d40dc93d11275415e40397ea834626e2d400bcd1a6176415e40b33ff5b4686e2d40b6bfb33d7a415e4087d1bd98776e2d40e22b706880415e407bb9f4d48f6e2d403288b43286415e401beb877da76e2d40c0dda34888415e40db807456b06e2d40dd94f25a89415e40b03d0edeb26e2d40a764ef7b8a415e40e6da06a4b36e2d40d05092648c415e40ff9e0e1ab06e2d408d2782388f415e40d5ce30b5a56e2d405cae7e6c92415e405fb532e1976e2d4090a1630795415e408df3925a836e2d4077595d9896415e400d800239726e2d409558631a97415e408c7c0338626e2d40959d7e5097415e40350c1f11536e2d4000dea74f97415e406302c81a3f6e2d4024d1cb2896415e401aea6635136e2d4090fd874f95415e40abd84e4af76d2d401943ef4394415e407b93f0ceeb6d2d40a388563893415e400262122ee46d2d40d942908392415e40c2da183be16d2d40),
(129, 'Saint John Street', 'residential', NULL, NULL, 'way/24053751', 0x0000000001020000000700000024d1cb2896415e401aea6635136e2d4099bb96908f415e4083d9a95e236e2d4043bcbf8b88415e404b896e07346e2d405176e91585415e400ad7a3703d6e2d405dc87e7184415e407ffb9529416e2d40a51bbc0a84415e4083c0caa1456e2d40e22b706880415e407bb9f4d48f6e2d40),
(130, 'Saint Matthew Street', 'residential', NULL, NULL, 'way/24053752', 0x000000000102000000060000003288b43286415e401beb877da76e2d405bea20af87415e40d2a755f4876e2d40cc2c9d6a88415e40222933ef826e2d404e78ae948a415e40d36295777a6e2d4011dec3ca8d415e407f6f2e59706e2d407b46c77a8f415e40ef49719f666e2d40),
(131, 'Saint Mark Street', 'residential', NULL, NULL, 'way/24053753', 0x0000000001020000000b0000006aa4a5f276415e403c58b55a166e2d40f816d68d77415e40e37f3c050a6e2d409ec838eb78415e4046f6f708eb6d2d40b6f0619b79415e40367a90f9db6d2d407aec1d247a415e40b066ae1dd66d2d406e3bc8467b415e409665e31cd06d2d40d228136d7d415e4067edb60bcd6d2d40fb7612117e415e4003006ce5ca6d2d40724b50687e415e40f9ed9007c76d2d40606a95aa7e415e4062cbe149c16d2d400c52955b7f415e407b551d28a66d2d40),
(132, 'Saint James Street', 'residential', NULL, NULL, 'way/24053754', 0x0000000001020000000400000097cba1a06f415e40ff66182df66d2d405baa1ca471415e40efdcc545ff6d2d40e70d411f76415e40682b8ab2126e2d406aa4a5f276415e403c58b55a166e2d40),
(133, 'East Los Angeles Street', 'residential', NULL, NULL, 'way/24053755', 0x00000000010200000004000000d927db1b57415e409fbf1ab1606c2d407554da8761415e40cfdc9e7b6a6c2d404da83baa75415e409067976f7d6c2d400583103576415e408b3acec87b6c2d40),
(134, 'West San Francisco Street', 'residential', NULL, NULL, 'way/24053757', 0x000000000102000000070000001a7b40ea40415e40dc5e775f3a6a2d40b29defa746415e4084fd8d2c4f6a2d404cb8a17348415e40cb619c64506a2d40b637ae354a415e40fc3960b24c6a2d409dec0b8d4c415e404f43af9a426a2d40979cc9ed4d415e40eb0dad04416a2d4095c1acab5d415e4069249ddc4a6a2d40),
(135, NULL, 'service', NULL, NULL, 'way/24053758', 0x00000000010200000003000000404a91216c415e40b5b574bb4d6a2d400ad80e466c415e400aacd2cc496a2d40eb877da76e415e407aa3fbde4b6a2d40),
(136, 'Quezon Street', 'residential', NULL, NULL, 'way/24053759', 0x000000000102000000070000008f50d8ea97415e4032cb9e04366b2d40a9bef38b92415e4083fcc79d2d6b2d40134f2ca688415e40f7eeeab01d6b2d4079d5b95887415e403489d57a1a6b2d4092a7f63386415e4024bac216166b2d402f36ad1482415e4016a6ef35046b2d40006d50a074415e40860c9a4ccb6a2d40),
(137, 'Osmeña Street', 'residential', NULL, NULL, 'way/24053760', 0x000000000102000000060000004c8281316c415e40edf5ee8ff76a2d40048e041a6c415e407e1ea33cf36a2d407ba75da76c415e40ae3720f8ce6a2d4098d4754d6d415e409a3e3be0ba6a2d40d4765d096e415e4043ce56b9ab6a2d407e213f7672415e4012e390685d6a2d40),
(138, 'Marcos Street', 'residential', NULL, NULL, 'way/24053761', 0x0000000001020000000a0000006fa6f8ae77415e40c02500ff946a2d40821a63cc82415e40d2f01c80c36a2d400787cdb689415e40d417f840e16a2d40838b70ee8a415e40ba0b395be56a2d406b15585b8c415e4095850a69e86a2d407cd9d1938d415e401dd9a6c2e96a2d409fc321c08e415e40c5ad8218e86a2d408eda0e5798415e4093ee9d87c96a2d40553607639f415e40e622be13b36a2d40731e04d39f415e40fe367aebb26a2d40),
(139, 'Garcia Street', 'residential', NULL, NULL, 'way/24053762', 0x00000000010200000005000000a08db7f097415e40acf82b09f5692d40766792fd98415e4049d51b5a096a2d40cf9552e199415e40d9a72dbf1d6a2d4081de65d09a415e407a692f47346a2d40731e04d39f415e40fe367aebb26a2d40),
(140, 'Magsaysay Avenue', 'tertiary', NULL, NULL, 'way/24053763', 0x00000000010200000012000000775f3a52a2415e4059cfff61016a2d40834f73f2a2415e407fdaa84e076a2d40a1377062a3415e4093fe5e0a0f6a2d40e7847588a4415e40c4e51d4c2f6a2d40526342cca5415e40548d5e0d506a2d40aae7ee84a8415e40911d650e936a2d4056702eb4a9415e40a16efb79ae6a2d40e3214212ac415e4020196140e56a2d406ca3f08fad415e4004b40820106b2d4054a63dcaad415e4099068f801b6b2d40b9e177d3ad415e4003a61d48286b2d40188e8c7aad415e401c5c3ae63c6b2d40d1e1c6d2ac415e408d3a843b616b2d401fdb32e0ac415e408f6c53e1746b2d4054eef439ad415e402497ff907e6b2d402a6cabfead415e4029e1ae038c6b2d4023ebba01b0415e40b5eb94fda96b2d40bd1f1219b1415e406cac6983b86b2d40),
(141, 'E. Aguinaldo Street', 'residential', NULL, NULL, 'way/24053764', 0x0000000001020000000e00000078da75ca7e415e40eb13e5773f6b2d40cf86fc3383415e4090edc6cc4f6b2d4080b56ad784415e40f3ba3434546b2d40dfe57d7786415e408640892a576b2d4039f878d78f415e40797b6bbb646b2d404f1432a193415e40e1bd59396a6b2d403157ab1b94415e40f8f9efc16b6b2d404f289f7994415e40f1d4230d6e6b2d40cceac2b494415e401f4d501e716b2d407e92962595415e40fc9353967c6b2d4084f3a96395415e4024bfd941806b2d409cd6b7dd95415e404c32175d836b2d40fa0967b796415e40b01f6283856b2d401d50db2b98415e40af473c34876b2d40);
INSERT INTO `streets` (`Id`, `Name`, `Highway`, `Oneway`, `OldName`, `StreetId`, `Geometry`) VALUES
(142, 'Santa Barbara Street', 'residential', NULL, NULL, 'way/24053766', 0x000000000102000000070000001d50db2b98415e40af473c34876b2d4065a318c597415e40c00067ce9f6b2d409586753e97415e40ebe2361ac06b2d40e251cf2797415e40dfad878acc6b2d40eea0c84997415e4044d8953bd86b2d40066dcdb197415e406e60bc30e36b2d404d75b7a198415e40361081d9f36b2d40),
(143, 'J. P. Rizal Street', 'residential', NULL, NULL, 'way/24053767', 0x0000000001020000001100000053ca6b2574415e4097d2e92faa6b2d402ea0617b77415e40a12c7c7dad6b2d405f4d542580415e40dee34c13b66b2d40564a2aae85415e40a6e6bc10bc6b2d40a326553687415e4010913fbdbe6b2d40f61e78c688415e4037740ef9c26b2d4060144e1c8a415e4011ce0248c86b2d4000659d3b8b415e40c26c020ccb6b2d40bece97288c415e40ecd74235ca6b2d401deb3df08c415e401116bab7c76b2d40c3b645998d415e405bda5f2cc26b2d408268f7f58d415e4048fe60e0b96b2d40228ed02a8e415e402ff598edaf6b2d4058cfa4a88e415e4060bb6a54966b2d40edbc8dcd8e415e40f2bb4450906b2d407558e1968f415e403234434f6f6b2d4039f878d78f415e40797b6bbb646b2d40),
(144, 'A. Bonifacio Street', 'residential', NULL, NULL, 'way/24053769', 0x000000000102000000030000005f4d542580415e40dee34c13b66b2d40b13f3f4283415e4044352559876b2d40dfe57d7786415e408640892a576b2d40),
(145, 'Recto Street', 'residential', NULL, NULL, 'way/24053770', 0x0000000001020000000800000078da75ca7e415e40eb13e5773f6b2d40ff9da34481415e409b8e006e166b2d40d5bf35c181415e40dc8882740c6b2d402f36ad1482415e4016a6ef35046b2d40b12bd26982415e40e013eb54f96a2d4005583f9182415e405c40c3f6ee6a2d409f4a17ac82415e400a8d1656e06a2d40821a63cc82415e40d2f01c80c36a2d40),
(146, 'Quirino Street', 'residential', NULL, NULL, 'way/24053771', 0x0000000001020000000d00000054dc5d0c8a415e4064daed693d6a2d4048872c778b415e402fd16a92696a2d40f4cdeca98b415e40c086962b726a2d4089a4ccbc8b415e407412a5187b6a2d40e27904928b415e40774b72c0ae6a2d40245289a18b415e40f6813f57b66a2d40593739d78b415e40522ae109bd6a2d40f485353a8c415e40fbcbeec9c36a2d409fc321c08e415e40c5ad8218e86a2d407ab0202892415e40d5c853fb196b2d402009fb7692415e402b244f48216b2d40d33da18d92415e40daca4bfe276b2d40a9bef38b92415e4083fcc79d2d6b2d40),
(147, 'Ramirez Street', 'residential', NULL, NULL, 'way/24053773', 0x0000000001020000000e00000015db49e9be415e4059935d1f8c6a2d40d670917bba415e4029a1aaf8756a2d40187ac4e8b9415e40958be722746a2d403609394ab9415e407e079a2a736a2d40a7ad11c1b8415e40f5238ff1726a2d4007e7f80db8415e40dd0fd319736a2d4037b34c75b7415e40cb48bda7726a2d4031242713b7415e404ffffe39716a2d40f151da76b5415e4083a7ebe4676a2d407adc5ca1b4415e409db3aaca636a2d40aa91a7f6b3415e40fd4b5299626a2d401b086e49b3415e409efb613a636a2d40458ab784b2415e40d2c034b1656a2d40aae7ee84a8415e40911d650e936a2d40),
(148, NULL, 'residential', NULL, NULL, 'way/24053774', 0x00000000010200000007000000965f0663c4415e4064def4786b6a2d40027855b1c2415e406ae3e36e6b6a2d40f68ab84ac1415e4086dcb17d6d6a2d40d3fc8c66c0415e403d38e9c7706a2d40eb6f09c0bf415e4052ec0d63776a2d406e7fd360bf415e40786748707e6a2d4015db49e9be415e4059935d1f8c6a2d40),
(149, 'Sikatuna Street', 'residential', NULL, NULL, 'way/24053775', 0x0000000001020000000a0000002cb24236b5415e403a2927350f6b2d4044392c68b5415e405962afc10c6b2d40e530f378b5415e40bfd76bd5096b2d400e68e90ab6415e40d18b7f44b86a2d40b5649f11b6415e406344a2d0b26a2d403ed57cf0b5415e402a5206b3ae6a2d4056a41d92b5415e40c6f4296cab6a2d4033d1d677b4415e401cc3adcca56a2d40eb3b1ae2b3415e40d6a65604a46a2d4045b52d6fb3415e4083f0b270a36a2d40),
(150, 'Osmeña Street', 'residential', NULL, NULL, 'way/24053776', 0x00000000010200000002000000b13f3f4283415e4044352559876b2d4058cfa4a88e415e4060bb6a54966b2d40),
(151, NULL, 'service', NULL, NULL, 'way/24053777', 0x000000000102000000020000006de4ba2965415e4079735d9d086b2d40d0c254e95d415e404bd356db036b2d40),
(152, 'Benevolence Street', 'residential', NULL, NULL, 'way/24053778', 0x00000000010200000006000000e86c5c5a68415e402bb3525271692d401e520c9068415e40b9c3263273692d40fa4a7bde68415e40183cf14174692d409ebfbff76d415e40b2e611ed74692d400f8f0e596e415e402f08f6a974692d40804754a86e415e4095a58c6e73692d40),
(153, 'Garcia Street Extension', 'residential', NULL, NULL, 'way/24053780', 0x0000000001020000000a000000221b48179b415e40ae9b525e2b692d4052b9895a9a415e40113eef213c692d4052d32ea699415e40e41f6c674e692d402f17f19d98415e40bfe5fbf37e692d40a736829e97415e4072a8df85ad692d4089f260e696415e409db58075c1692d40c580dbc996415e404824c09fd0692d4018963fdf96415e40ca479c5fde692d40590f046d97415e4093a7aca6eb692d40a08db7f097415e40acf82b09f5692d40),
(154, 'East Fresno Street', 'residential', NULL, NULL, 'way/24053782', 0x0000000001020000000400000076e7e4a05f415e4000492245ae692d40d5def1376b415e40db27918ebc692d409e013ff46e415e40a977a7f1c1692d409bd5f14e74415e40c8a53b99c9692d40),
(155, NULL, 'residential', NULL, NULL, 'way/24053783', 0x00000000010200000003000000987219926e415e402eb76a8df7692d40e5828eb16e415e4013510251e6692d409e013ff46e415e40a977a7f1c1692d40),
(156, 'Charity Street', 'residential', NULL, NULL, 'way/24053784', 0x000000000102000000070000003f8b4a8f4b415e40d309b2af86692d4014d852f64c415e40ff6cf5e681692d40ea6c12cd4d415e4006da780b7f692d40c64bdccf4e415e40723447567e692d40b980e1a650415e4000451b3680692d4009980a3b56415e40a8c64b3789692d4015e4672357415e4008173c9688692d40),
(157, 'Amity Street', 'residential', NULL, NULL, 'way/24053785', 0x0000000001020000000d0000001b3dc8fc6d415e40a5ebd33b26682d4056ae015b6f415e40bb4f447529682d40d1306b1874415e403f236cd333682d40f387b02b77415e400e23ced435682d40b752be5678415e40698eacfc32682d40e02af46679415e403e76172829682d402df3b1167a415e4039c7ca7910682d402dae96e079415e40f01307d0ef672d40b01c210379415e402dc7d056ca672d40f8b479d278415e4014e6e214c2672d406987646d78415e40e745dc52bd672d408159a14877415e40193e7d5fb7672d409549682673415e40ca77dfe7ae672d40),
(158, 'Butalid Road', 'service', NULL, NULL, 'way/24053796', 0x000000000102000000100000005c77f35407425e40fd378a07ef662d4079beb04607425e406e32aa0ce3662d40a92b442c07425e40c0ab8a15da662d40744694f606425e4094731882d2662d4026c3f17c06425e40ebd10ac2cb662d403f366ed605425e40b26fdd83c6662d40527c218903425e405422e417b9662d409f6120be02425e406f06c94cb3662d4076fc170802425e400107a348ad662d4024d6e25300425e406a9f330e9a662d4065694c2d00425e40d6d127a897662d40b334a61600425e4013245b0295662d405f364b1300425e4039f2406491662d4089cc012700425e40edf0d7648d662d401ee8fc6f00425e40f008b83187662d4052b06b2002425e40f39e14f769662d40),
(159, 'Butalid Road', 'service', NULL, NULL, 'way/24053802', 0x00000000010200000019000000b8c19a1430425e405b3fa2ae5a662d40e43e83972a425e40c69970f959662d40fd5b131c28425e40d718cffb5a662d40e692aaed26425e403691990b5c662d4034338eec25425e40417b9a385e662d409b94dd2722425e4046c549ab6b662d40b602f9c81c425e40ace4637781662d40ecf07cab1a425e401e81e4428a662d4053f06f2b18425e404951c2a794662d4030ef16ed16425e408ebdcdd199662d40e415889e14425e40769e1d15a4662d4043948a2114425e40e1d80ea1a5662d40eaef00aa13425e4058ad4cf8a5662d403e1f0a0b13425e4011018750a5662d40c237a85810425e405508f53e9f662d404c101a660d425e40419c871398662d4019de510809425e4078842e3c8a662d40cca266fe07425e40565e978686662d40dfb4cf1907425e406a1db00683662d40689b768c06425e40dc9c4a0680662d40334399fc05425e4008b8d6cd7b662d402728ea7104425e4044858f2d70662d40f8d4fbd703425e40c85bae7e6c662d40dba7e33103425e403b4bda9e6a662d4052b06b2002425e40f39e14f769662d40),
(160, NULL, 'service', NULL, NULL, 'way/24053804', 0x00000000010200000005000000d4b3c5da04425e40f175638bee662d401bbf4b0405425e403b0f385cf5662d40c8d7f91205425e4028e08dbbf7662d4069cfc02305425e408680327cfa662d40865b994b05425e405340daff00672d40),
(161, 'Kappa Street', 'residential', NULL, NULL, 'way/24053805', 0x00000000010200000009000000b52ad3791e425e40757286e28e672d4085da25602a425e40f3a55c86a4672d407ecffef62b425e40453c235ba7672d4042f394302e425e40ea40d653ab672d40f452b1312f425e40ae7e11d9ac672d403bb7bf6930425e4012fccadead672d40cf2b43c131425e40b3abda7fae672d40f65091f936425e404d0e44bbaf672d406709d74837425e40410466cfaf672d40),
(162, 'Saint James Street', 'tertiary', NULL, NULL, 'way/28296728', 0x000000000102000000160000004df2c8c4d2425e4050a6762bf0662d4081ba3775d4425e40d0fc2081f5662d4063111ec8d5425e4046f93889f7662d40a4fa7376d7425e409e245d33f9662d4097ea5d17d9425e40aae683aff9662d4073254c62da425e40633abe07f9662d406041f56adb425e4075914259f8662d40f4705d8cdc425e405730e01bf9662d40b82462a5dd425e4086387b0cfb662d4056911b8fe3425e409a99f4520c672d40e958ef81e7425e40f4b9241818672d40e824a5eae8425e4010dbccd71b672d40dbfd8579ea425e405b24ed461f672d405ea85725ec425e402adc97d821672d40b0a07ab5ed425e402904728923672d40fbb5508df2425e4033164d6727672d4017da9486f5425e4085ac133c2a672d40ae0a79a9fd425e40bdee63bb31672d4060afb0e0fe425e40b0c4a81034672d409bdbce0800435e40bad683ee37672d408ee55df500435e40e7768ab03c672d40b7d100de02435e40e7db27ec47672d40),
(163, 'Ester Street', 'tertiary', NULL, NULL, 'way/28296729', 0x00000000010200000007000000f17f4754a8425e40c07d78f1d9692d40b6f1cc70a8425e4017dc6a31d3692d406eb2fcafa9425e40e22f7777ae692d40eaa2320faa425e4035f10ef0a4692d404f3459edab425e40b58b69a67b692d406c02b111ad425e4000a6b1625d692d4095c041d6ae425e402b2dc83b2c692d40),
(164, 'West San Jose Street', 'residential', NULL, NULL, 'way/28520462', 0x000000000102000000040000006eade5843f415e40144438c1926a2d400fd0228040415e4059b043eb976a2d40c949175149415e40dd836b49a26a2d404841a66b5c415e401693ed32b26a2d40),
(165, 'P. Macapagal Street', 'residential', NULL, NULL, 'way/28520465', 0x000000000102000000020000003307f7b990415e40ca68893a186a2d408eda0e5798415e4093ee9d87c96a2d40),
(166, 'Recto Street', 'residential', NULL, NULL, 'way/28520477', 0x00000000010200000002000000fe4fb46183415e40323cf6b3586a2d40821a63cc82415e40d2f01c80c36a2d40),
(167, 'Riverside Street', 'residential', NULL, NULL, 'way/28520484', 0x0000000001020000000e000000bd923f7331415e40dd26dc2bf36a2d40bd642d4f31415e40350a4966f56a2d40f9de3a5a30415e408e2a792b016b2d4060cac0012d415e40b581e096346b2d40f0b8f2a32b415e4027abd84e4a6b2d40376854852b415e4012842ba0506b2d409cba97a02b415e40b13b3833556b2d40134abac12b415e40016a6ad95a6b2d40966df13a2c415e40928433ae6e6b2d4096b20c712c415e4072f508da896b2d40e3f093b42c415e40488ecfbfb86b2d404e31bdb32c415e40f92ccf83bb6b2d40789961a32c415e4099c00875ec6b2d40d1cabdc02c415e4042661d44216c2d40),
(168, 'Madre Cacao Street', 'residential', NULL, NULL, 'way/28520504', 0x000000000102000000060000008138b46dbd415e4069e9656f846c2d403cb54478c5415e40a7fee66ad06c2d408fb00342c6415e40d4c6c7ddd66c2d406aa6d656c7415e4082250d24de6c2d405c7cc0f2d6415e403e26ad53406d2d4090f63fc0da415e40869cad72576d2d40),
(169, 'Aratilis Street', 'residential', NULL, NULL, 'way/28520505', 0x000000000102000000050000008fb00342c6415e40d4c6c7ddd66c2d4074fdcc6acb415e4039a80e03a76c2d40b5e62219cd415e400129fbf8956c2d4025f8f076ce415e40859a7c0e876c2d40a1b4dc3ed0415e40c2dabd816e6c2d40),
(170, 'Narra Street', 'residential', NULL, NULL, 'way/28520506', 0x0000000001020000000400000074fdcc6acb415e4039a80e03a76c2d40a21c16b4da415e4028be350b0f6d2d4084ec61d4da415e40bc8b4171116d2d4084ec61d4da415e40d83c5810146d2d40),
(171, NULL, 'footway', NULL, NULL, 'way/28520560', 0x00000000010200000006000000b0e99cfa9b415e40ee2affb517682d408e05854199415e40d9470268ef672d4011154fe298415e409a982ec4ea672d408faf986c97415e40b79fe7aad4672d40184e886f97415e40e8829fddc6672d40ac808cca97415e40545ee113a1672d40),
(172, NULL, 'footway', NULL, NULL, 'way/28520562', 0x000000000102000000030000008e05854199415e40d9470268ef672d40ecb6555a90415e40a29927d714682d40193d128a88415e407935e5af35682d40),
(173, NULL, 'footway', NULL, NULL, 'way/28520564', 0x000000000102000000060000002f0b372a81415e40574ff74bd5672d4041310d1e81415e4031e7be4120682d40dc0cdc2681415e40de6ae74537682d402eeef5a482415e40f7d84c744c682d40f2b803d083415e40c5d5b7825c682d40e5d6ff9485415e4006b75acc74682d40),
(174, NULL, 'footway', NULL, NULL, 'way/28520565', 0x00000000010200000002000000fd71569f86415e406359d537d5672d40b50aac2d86415e40aec6c848ac672d40),
(175, NULL, 'footway', NULL, NULL, 'way/28520567', 0x00000000010200000003000000fd71569f86415e406359d537d5672d402f0b372a81415e40574ff74bd5672d403ddf05007d415e40a5486359d5672d40),
(176, NULL, 'footway', NULL, NULL, 'way/28520577', 0x000000000102000000030000007aef5ea486415e406655df54ff672d4088e013468e415e40c42055b9f5672d4011154fe298415e409a982ec4ea672d40),
(177, NULL, 'footway', NULL, NULL, 'way/28520581', 0x00000000010200000005000000ea37b81993415e4040a8e6cd3c682d40ecb6555a90415e40a29927d714682d4088e013468e415e40c42055b9f5672d40a6fc5a4d8d415e40df65d01acd672d400cf6155a8c415e40c3352d67a5672d40),
(178, NULL, 'footway', NULL, NULL, 'way/28520583', 0x00000000010200000003000000b1a54753bd415e40b6f86fb955672d400381295ec0415e4087ffcfbc77672d4017a87b53c7415e404e68ed11c5672d40),
(179, NULL, 'footway', NULL, NULL, 'way/28520584', 0x00000000010200000003000000f7ef5586cc415e400e29ab8ec1672d40e313573ac4415e4014feb1b563672d406849360dc0415e401c672ecb32672d40),
(180, NULL, 'footway', NULL, NULL, 'way/28520585', 0x00000000010200000003000000b40584d6c3415e4048bb760e0a672d4087b6ad77c9415e40e86b96cb46672d4018cb9992d1415e408dc00e52a6672d40),
(181, NULL, 'footway', NULL, NULL, 'way/28520588', 0x0000000001020000000300000028c819d4c8415e401be1a3b4ed662d405bdda0acce415e403d2828452b672d40219221c7d6415e40e3c4573b8a672d40),
(182, NULL, 'footway', NULL, NULL, 'way/28520593', 0x00000000010200000006000000a5efda4ad4415e406f7e688b10672d405bdda0acce415e403d2828452b672d4087b6ad77c9415e40e86b96cb46672d40e313573ac4415e4014feb1b563672d400381295ec0415e4087ffcfbc77672d40e4a08499b6415e4039a2d68fa8672d40),
(183, NULL, 'footway', NULL, NULL, 'way/28520601', 0x00000000010200000007000000b50aac2d86415e40aec6c848ac672d400cf6155a8c415e40c3352d67a5672d409781148692415e40d20f34b09f672d40ac808cca97415e40545ee113a1672d406ca68cc9ac415e40b196f1a5a6672d40d60e9079ae415e40ab21718fa5672d40e0377469b2415e4075f002db77672d40),
(184, NULL, 'footway', NULL, NULL, 'way/28599550', 0x0000000001020000000300000063c4f47379415e4057276728ee682d40ad2c76a073415e40d9107750e4682d403507ad2c76415e400e19ea0b7c682d40),
(185, NULL, 'footway', NULL, NULL, 'way/28599553', 0x0000000001020000000a0000000ddc268172415e4001fd193966682d40cb76cfcb72415e402ca51ded6e682d4030f7240b73415e40ad437fb273682d40601c018173415e4022b028db76682d403507ad2c76415e400e19ea0b7c682d40dae3857478415e4002c754b07c682d4045662e7079415e40146690717b682d40508479347a415e40569dd5027b682d40ebb8d04b7b415e40792b01e77b682d40d875b9d27c415e40b31d9d0480682d40),
(186, NULL, 'footway', NULL, NULL, 'way/28599558', 0x0000000001020000000300000096873bcdb8415e400926edfc91682d40a9d903adc0415e40c8a9e7ee84682d4089809e61c5415e407f30f0dc7b682d40),
(187, NULL, 'footway', NULL, NULL, 'way/28599565', 0x00000000010200000002000000ee485057d2415e40a45b0aa3b4662d40361bd077dc415e40694d98d5e0662d40),
(188, NULL, 'footway', NULL, NULL, 'way/28599576', 0x000000000102000000020000009fc7cd15ca415e40bd8bf7e3f6672d40bcf4e5bbca415e40580a37cfc7672d40),
(189, NULL, 'footway', NULL, NULL, 'way/28599579', 0x000000000102000000040000002c2e8ecacd415e4071917bbaba672d40d5e940d6d3415e40bbdbab45fa672d40a5486359d5415e40347d1b0703682d403164d064da415e40560850f811682d40),
(190, NULL, 'footway', NULL, NULL, 'way/28599580', 0x000000000102000000020000009fc7cd15ca415e40bd8bf7e3f6672d403735d07cce415e40dcf0603024682d40),
(191, NULL, 'footway', NULL, NULL, 'way/28599583', 0x000000000102000000020000003735d07cce415e40dcf0603024682d40577d0970d5415e40662728ea71682d40),
(192, 'First Street', 'residential', NULL, NULL, 'way/28599652', 0x00000000010200000005000000c29c45941b425e40c2d375f233672d40f209d9791b425e40c1fb4fa335672d40d5100b6b19425e40c3da73f453672d4035d7c45d18425e402d324b4c61672d40dcd9b2d716425e40882aa1606b672d40),
(193, 'Aguirre Compound', 'residential', NULL, NULL, 'way/28599661', 0x00000000010200000003000000ceed1461f9415e40069156c6d0672d40b9533a58ff415e40903e9c76e7672d40f07be58b07425e40b5abebab06682d40),
(194, 'Second Street', 'residential', NULL, NULL, 'way/28599688', 0x0000000001020000000c000000f85e324404425e40a21babde2b682d4069a1aeff04425e408b32c0aa1f682d407477425406425e4016f1e72510682d40f07be58b07425e40b5abebab06682d408555061f14425e40327d0adbaa672d404da9013917425e40eabe524c94672d40f446f7bd17425e40fe55911b8f672d4053c25d0718425e409ca8007388672d402971c22918425e40a6c5cf3582672d409a88c8fa17425e402c4c3a257b672d4053dc025317425e402aef99db73672d40dcd9b2d716425e40882aa1606b672d40),
(195, 'Bayani', 'residential', NULL, NULL, 'way/30412162', 0x0000000001020000000200000080457efd90425e406b234333f4682d40e8644e3c8c425e40c1edbf84c0682d40),
(196, 'Champaca Street', 'service', NULL, NULL, 'way/33191947', 0x0000000001020000000e000000099e8c3bef415e408665225b4c662d400eff9f79ef415e407dd8c17751662d4091819774ef415e40d333bdc458662d401be1a3b4ed415e40f35a649698662d40b0e83125ed415e40e335afeaac662d40c872b790ec415e40b5af9701c2662d4099678066eb415e40a6bcb1fbe9662d40820ea958eb415e40ef7d607df2662d4058a60469eb415e400facf424fa662d405e4c33ddeb415e403784cf7b08672d404b1d893cee415e4012baf0283a672d4079399105f1415e400301d7ba79672d403dc21f34f1415e40a6553e1581672d400e277a2af1415e40d70231bf89672d40),
(197, NULL, 'service', NULL, NULL, 'way/33191963', 0x0000000001020000000f000000ecc5ab07a7415e40cd4a49c5b5682d40383dde9aaa415e40f8f65388ec682d40fbbf3456ac415e403505d78118692d40cbaec5b8ac415e40da5141ea1b692d40a1fe6959ad415e40b0e600c11c692d4012b4136fae415e407b4908fb1b692d4023d74d29af415e40c9aa083719692d40b84e6dbaaf415e40cd0aa07312692d40d57b8560b0415e40b308c556d0682d40ca439550b0415e405f155e38c6682d4047938b31b0415e40db69108bbd682d40592f2bb9af415e4030f0dc7bb8682d40e90c8cbcac415e4035705177af682d40d2d3916daa415e402c7e5358a9682d40ecc5ab07a7415e40cd4a49c5b5682d40),
(198, 'Moss Street', 'residential', NULL, NULL, 'way/41172150', 0x000000000102000000020000005c1e6b4686425e40683cb60a07672d4024ffdd4c96425e4034d18cea19672d40),
(199, 'Olive Street', 'residential', NULL, NULL, 'way/41172151', 0x000000000102000000020000009e9acb0d86425e40d215116a2b672d4020a79ebb93425e4016574bf03c672d40),
(200, NULL, 'service', NULL, NULL, 'way/41172758', 0x000000000102000000020000009a8ddf2582425e4056e7621dd8672d40b1b508d682425e40a5654925e1672d40),
(201, NULL, 'service', NULL, NULL, 'way/41172759', 0x00000000010200000002000000c6f3be967c425e40896f7209d1672d40246651337f425e40fbb5508df2672d40),
(202, 'Rockville Avenue', 'residential', 'yes', NULL, 'way/41178515', 0x000000000102000000030000007e09cb8e43425e40f002db77fb662d405fb939f045425e400d4f54dbf2662d400b42791f47425e404881aa76f2662d40),
(203, 'Rockville Avenue', 'residential', NULL, NULL, 'way/41178516', 0x000000000102000000020000006fd39ffd48425e4004a50d2cec662d40e9bf626850425e4023cca3d1d3662d40),
(204, NULL, 'residential', NULL, NULL, 'way/41312351', 0x00000000010200000003000000fb29e9bca1425e4089ea52c83a692d4091f52fa49e425e402d54a3fc49692d406d4d5f749e425e4097fe25a94c692d40),
(205, NULL, 'residential', NULL, NULL, 'way/41312354', 0x00000000010200000002000000fb29e9bca1425e4089ea52c83a692d404c8c65faa5425e4096c5692d71692d40),
(206, 'Franciscan Street', 'residential', NULL, NULL, 'way/41379197', 0x0000000001020000000e0000002d67a5ff9b425e40e2fb2ce0af672d4068ec4b369e425e40bb8be6b79e672d40086bad799f425e400700d8ca95672d40fb157ce4a0425e40ca4807358d672d40f41ec253a3425e40d635ff5481672d40a667d542a4425e40a84d41237d672d406974626aa6425e40bfdc820074672d40c60b337eab425e4017ceda125e672d40b4869c08ac425e40a86620e05a672d4090c4268dac425e40e08b8a9356672d407e6da23bad425e40080db38641672d4000a2aa53af425e40ebf2f79c05672d40fe7e315bb2425e403d201a27cf662d40f63c2421b6425e402263ff869a662d40),
(207, 'Noguera Street', 'residential', NULL, NULL, 'way/41379251', 0x00000000010200000002000000f76173c490425e40b19c2919a5682d40dc5d0c8a8b425e4032aa0ce36e682d40),
(208, 'Luz Street', 'residential', NULL, NULL, 'way/41802909', 0x000000000102000000060000007345ce67e5425e40dad3c4f132692d402b966c86e5425e40f59ac35a21692d4025a886a2e5425e4027bb3e181d692d40b4d59b07e6425e40959d7e5017692d401f2dce18e6425e40dfd1b5e512692d400d4c135be6425e408984a570f3682d40),
(209, NULL, 'service', NULL, NULL, 'way/46332526', 0x00000000010200000004000000ae8ed25b72425e4022cc481861692d40960a856371425e40b2f105d26a692d4098e2056c62425e40f689f2bb9f692d40e3c0502c5c425e40afa7678bb5692d40),
(210, NULL, 'service', 'no', NULL, 'way/46332765', 0x0000000001020000000900000027f15e5a79425e4099c57a59c9692d4037ddb2437c425e409a80badcbb692d400753ded87d425e40463aa869bc692d40bf2a172a7f425e409ba0979bb9692d4053cdaca580425e40c366800bb2692d4052c7743282425e406a8e07b6a5692d402c2405bb86425e40899bae8273692d40a357039486425e408451ff0f66692d400f6db6a885425e40799dc36b4d692d40),
(211, 'Katipunan Avenue', 'secondary', NULL, NULL, 'way/46990157', 0x00000000010200000010000000394ab95656415e4037b00bf5aa6c2d408c5f1d6c56415e40b9c1f5cda26c2d40d927db1b57415e409fbf1ab1606c2d400f52a68757415e40d4bda9a33e6c2d405c5f7f6d58415e40ff0af4e4f56b2d4050b1c5c958415e40509abcb7d86b2d4002e66be058415e4041333e82d16b2d40677dca3159415e406d3cd862b76b2d40f05d39315a415e40de40dc30656b2d407267cb5e5b415e40441e1c47076b2d407e9fbb6e5b415e40eda2433b026b2d404841a66b5c415e401693ed32b26a2d4095c1acab5d415e4069249ddc4a6a2d403b037ee85d415e40e8b00cbb396a2d40d5dbb0b75e415e408772fd16f8692d4076e7e4a05f415e4000492245ae692d40),
(212, 'Atlas Road', 'tertiary', 'no', NULL, 'way/46990641', 0x00000000010200000002000000fdde01f9ed415e40bd3b8d0f0e6d2d4088e82164ea415e401f3cc90c0a6d2d40),
(213, 'Atlas Road', 'tertiary', 'no', NULL, 'way/46990642', 0x0000000001020000000500000088e82164ea415e401f3cc90c0a6d2d4029b5728ae9415e40924bd2eb056d2d4065b9b601e9415e407672e19b016d2d40c47cd4bae8415e40debfc3fefc6c2d40a7abe05ce8415e402e895869f76c2d40),
(214, NULL, 'service', NULL, NULL, 'way/49230697', 0x0000000001020000000c00000065b26e72ae415e40ea8dffa787692d40f0a72105aa415e40fe94cf9783692d4038fb5e9ea9415e40ed15719582692d407a77bf65a9415e4035e213fc80692d4003e89c44a9415e40fb17528f7e692d40fdcba43ca9415e40c04d90227c692d404a7d59daa9415e40af2fc84c58692d40a3aeb5f7a9415e4099cb571355692d402676c828aa415e406ac3bc2253692d40e4277a85aa415e40ca5b64f151692d40797187f2aa415e401855d0fe51692d408341e3d3ad415e4081b79b3b55692d40),
(215, NULL, 'service', NULL, NULL, 'way/49230698', 0x000000000102000000020000005e5cf45fb1415e40fd0571d4c0692d40360f1604c5415e402d76a0f3bf692d40),
(216, NULL, 'service', NULL, NULL, 'way/49230699', 0x0000000001020000000e0000002e4b85c2b1415e406f2475a7e0692d40f937c368b1415e4047f9eefbdc692d40f3edb83cb1415e40d9b11188d7692d400b308738b1415e40ad31e884d0692d405e5cf45fb1415e40fd0571d4c0692d4028bc5f60b1415e408c193ca7b4692d40f3edb83cb1415e402bd43f2dab692d40ffb27bf2b0415e40f90670c4a4692d4065b26e72ae415e40ea8dffa787692d40e304018dad415e40cde7dced7a692d400107a348ad415e400d52f01472692d400d288a46ad415e40e38112b067692d4030d05a76ad415e40d68228a95d692d408341e3d3ad415e4081b79b3b55692d40),
(217, 'Barangay San Bartolome Road', 'tertiary', NULL, NULL, 'way/50556976', 0x0000000001020000001a000000e33e28deb7495e401bc8693e9d352c401e37fc6eba495e407d75fae6a3352c406c8198dfc4495e409c30067bb8352c4044bbaf6fcc495e4088461c57c8352c40d2cec4cfda495e4093fa57fbe0352c401299034e004a5e402269dc4026362c4019eda7b51f4a5e40d37b743458362c407b9a385e264a5e40228ac91b60362c40efc9c3422d4a5e408d0c721761362c4026f26e76354a5e40c086962b72362c40590a92883a4a5e407f445db57c362c40b0e7c64f3e4a5e4041c758b78b362c40e9746a78444a5e408acdc7b5a1362c40cd70a8844c4a5e40d358b1aec0362c4057f9afbd604a5e40fdb90d0f06372c409468c9e3694a5e40cafb389a23372c40e6e4ea6c6d4a5e40b5d48beb29372c40a1534612734a5e40a2c2c71638372c407c54b252774a5e4096653ed642372c40193499967d4a5e40a77114c550372c40f90be2a8814a5e40fc3ca13259372c40049abe8d834a5e40bfbf9c3468372c40f7cec364854a5e4079fdeec27b372c400667f0f78b4a5e400b0dc4b299372c4055cecded944a5e402bb2e77cc2372c4004615dcb9a4a5e40e9dc4834dc372c40),
(218, NULL, 'path', NULL, NULL, 'way/51404464', 0x000000000102000000100000004a682673874b5e40bee5a03a0c3c2c4023f02ce68c4b5e40d81d41e0373c2c40f87b1810904b5e40772ff7c9513c2c40626e522c924b5e4060da8184723c2c40cc07043a934b5e40dc7af255973c2c40a193ef63964b5e4056a1dc11a93c2c40a68f0aad984b5e40a2b437f8c23c2c40100f176f9a4b5e404ee2bdb4f23c2c407b8e23319c4b5e40a59762580f3d2c40b5102e2e9f4b5e40d79efe582d3d2c40899c1958a24b5e40533f6f2a523d2c4029a215cea44b5e4055e5d6ff943d2c4063974d25a84b5e40ad1402b9c43d2c40022a1c41aa4b5e409582c9e8db3d2c406ca92803ac4b5e40c74ca25ef03d2c40a8209ad4ab4b5e4038818efbfb3d2c40),
(219, NULL, 'service', 'yes', NULL, 'way/86877098', 0x0000000001020000000d0000005b1d4afe71425e40a25ae95a206a2d40567a127d63425e40f0d5d86f376a2d407c629d2a5f425e40da6674513e6a2d4006ae3c925c425e4067576b72426a2d406089acda5a425e401efb592c456a2d4087d0f70956425e40912749d74c6a2d40a5a723db54425e403cc159a54f6a2d40bdbe7bec53425e406b3986b6526a2d409a30500853425e4098d98c78576a2d40caff3fa951425e40405bbd79606a2d406c45f69c4f425e4084e4ae6f716a2d4042f1be8550425e40cc07043a936a2d40b8a51f1e53425e4023b3c414f66a2d40),
(220, NULL, 'service', 'yes', NULL, 'way/86877107', 0x0000000001020000000400000057a30d7679425e403e062b4eb56a2d401a23c8f77b425e40fac4f0c7a36a2d40a90bc2267c425e40bf6ac07ba26a2d408b37328f7c425e40bcc568c29b6a2d40),
(221, 'Magsaysay Avenue', 'tertiary', NULL, NULL, 'way/91769156', 0x00000000010200000006000000bd1f1219b1415e406cac6983b86b2d40c8f20934b3415e4095f7ccedb96b2d402f2f6585c7415e4017ab178dc66b2d4026fb8cb0cd415e4099219fa1c96b2d404f498c54ce415e4003a4479dca6b2d400d2950d5ce415e4068d94933cc6b2d40),
(222, 'Villamor Street', 'residential', NULL, NULL, 'way/91769158', 0x000000000102000000050000005b61fa5ec3415e4049ec7f25fc6b2d408ba0d6d9b5415e408c8752d6ca6b2d4015b82baab4415e40b32d5e87c56b2d406ebe11ddb3415e4033d7b331c06b2d40c8f20934b3415e4095f7ccedb96b2d40),
(223, 'Oregon Street', 'residential', NULL, NULL, 'way/91769160', 0x0000000001020000000a0000001d50db2b98415e40af473c34876b2d40cff4126399415e40610619b7876b2d40875682209b415e40f036ca55876b2d4069ad68739c415e4062de3e06866b2d402642d94a9e415e40edb94c4d826b2d4010d0d8f2a5415e406334e14d6d6b2d40319413edaa415e407c03dda85f6b2d40fc94be6bab415e40a66e1dd25e6b2d4055223fd1ab415e402f52280b5f6b2d40d1e1c6d2ac415e408d3a843b616b2d40),
(224, 'Magsaysay Extension', 'residential', NULL, NULL, 'way/91769161', 0x0000000001020000000d0000006fa6f8ae77415e40c02500ff946a2d40006d50a074415e40860c9a4ccb6a2d407fc8b66771415e402e92d15c026b2d402022da3370415e40e2f20ea6176b2d40fc06dca96f415e400221a34d1f6b2d404a1aed026f415e40edf9f59e256b2d40da3631c96d415e409b1084752d6b2d4004a271f26c415e4033a3c453346b2d40da6a7b606c415e40e29178793a6b2d40c3595bc26b415e40e9d32afa436b2d4076bfaf366b415e4032056b9c4d6b2d40ff32294f6a415e4028bdca35606b2d40b95bedbc68415e4000a13f7e806b2d40),
(225, 'Marcos Street', 'residential', NULL, NULL, 'way/91771862', 0x00000000010200000005000000731e04d39f415e40fe367aebb26a2d40672b2ff99f415e40e54a98c4b46a2d4078db3b59a0415e407b05b353bd6a2d4019181ea0a0415e40d8857a55c26a2d406096d123a1415e403ce3569cc56a2d40),
(226, 'Joy Street', 'residential', NULL, NULL, 'way/91780717', 0x0000000001020000000b000000c49e2c6b51415e40fb720b02d0692d4047382d7851415e40c0a84995cd692d40a740666751415e4080d99832cb692d40061b8d3251415e4081f975f1c8692d407e4056a64e415e40a3e5400fb5692d40fc5069c44c415e40b18284cda5692d4056f88e754c415e409a46ee44a4692d407aff1f274c415e4035c9343fa3692d401568c1d54b415e40c4f9e5dda2692d408c56a4784b415e4047d80121a3692d40097888354b415e401768d201a4692d40),
(227, 'Diligence Street', 'residential', NULL, NULL, 'way/91780751', 0x0000000001020000000e0000009bf6de292e415e4096687f564f682d40ed331df02f415e408e4ea78647682d4004fae9e431415e40c33e4ba13d682d405d6a29c533415e400746b98f37682d4068b686ad34415e4091b932a836682d40df5916a735415e4019c5179238682d405517f03243415e40af496d9857682d4086dbebee4b415e407889a02067682d40e3bd0fac4f415e400917f2086e682d40f91b487254415e4022b028db76682d40c180142b59415e40f454e2957f682d40015361c75a415e40b7baf7cb82682d40b72ffbd060415e408db454de8e682d40f849ffdc61415e40a4a833f790682d40),
(228, 'Honesty Street', 'residential', NULL, NULL, 'way/91780754', 0x0000000001020000000c000000ea7d3e2542415e405ae6bee666692d40891e42a646415e40c25087156e692d403a1966b249415e408b4bfa2070692d4092ff6e264b415e40620097b66e692d40a37ecd284c415e404b0cb89d6c692d40baced0894e415e403c855ca967692d40a8493a144f415e40f06316eb65692d4029d7ca3a52415e40615e36f059692d40b8a51f1e53415e4063e6a7dd54692d40b8184d7853415e408487c4984f692d4076cafed453415e40bdf7dcae3c692d404c5fbeab54415e40adb13a2817692d40),
(229, 'Emerald Street', 'residential', NULL, NULL, 'way/92115285', 0x0000000001020000000a0000004cc3f01131425e40c209963490682d40bf8465c721425e40ba6d3a5d71682d40a6a3778519425e4046bcd0b760682d405f11572918425e40db3928bc5f682d404876001f17425e40bc900e0f61682d4084d9041816425e40ea78cc4065682d4096d4642115425e40ff74a84b6b682d40963325a314425e40723106d671682d405b1b745314425e40e0a0bdfa78682d40c65e398c13425e40c7a6f0fb92682d40),
(230, 'First Street', 'residential', NULL, NULL, 'way/92115292', 0x0000000001020000000e000000dcd9b2d716425e40882aa1606b672d40e98a08b515425e40c47cd4ba68672d40902e36ad14425e40de40dc3065672d400e6abfb513425e403287eea364672d40d382bcc312425e4013ded4f665672d4056c334c211425e40f3846fab6a672d40802e75eb10425e40dea5796c70672d405d4425bf0f425e40276728ee78672d409346167a0e425e40accabe2b82672d40db85e63a0d425e40be86e0b88c672d4024c5b6fb0b425e40d18ab9b596672d40cbc7a4750a425e40976d4cf49e672d4026a6b0f707425e4080de0a17a8672d4093f8815003425e40c1caa145b6672d40),
(231, NULL, 'tertiary', NULL, NULL, 'way/96321867', 0x0000000001020000000200000067dfcb33e5515e408a39083a5a152c408a9b093ce6515e40671f758588152c40),
(232, NULL, 'tertiary', NULL, NULL, 'way/96321868', 0x00000000010200000038000000ec9227ffc9525e400e1b1b704c112c408dd2a57fc9525e407818497144112c401c4b0e8ec8525e40d57b2aa73d112c40f598edafc3525e403227c34c36112c40b1b9b42bbe525e40c46f54b82f112c40b31078bbb9525e40ff64e7c825112c40748fb63bb5525e40f170f1a611112c40daa21694b3525e4056197c5006112c40e811482ea4525e409923d0059a102c4077b8c260a3525e40d8254ffe93102c40c1069f419e525e40f1ba7ec16e102c40eee2474698525e405e5cf45f31102c4001b6cd9e95525e40876d8b321b102c4055a3570394525e40fd8282f7fa0f2c40f78f85e890525e40ad286f91c50f2c40054aaf728d525e40a8dab80f8a0f2c4000db66cf8a525e40602aec585b0f2c402d5beb8b84525e401f7013a4080f2c40e819564c80525e40bd76c47cd40e2c40783cd2857d525e40244d17bdae0e2c4044d6bf907a525e4007b5dfda890e2c405382b4b574525e402453f4763a0e2c40391158946d525e408593d9c5d90d2c40adb0cf5268525e40348c71b4990d2c40892d98535d525e401c53c1f2310d2c40dbeb939254525e4069a9bc1de10c2c4046cd57c947525e409cd61297880c2c40a20dc00644525e4053b0c6d9740c2c40ab75e2723c525e405bc6979a4e0c2c40ee4dc23b2f525e40591245ed230c2c40ba2ccb7c2c525e40d5aeaeaf1a0c2c40c17c68d51d525e409e8834e0e20b2c4012bcc6d317525e40b9324d7dc50b2c406c7a50500a525e403586efb3800b2c4096ae0562fe515e40576eb3c23e0b2c40b0bd6081f9515e40ba2c26361f0b2c4024607479f3515e40bcf55091f90a2c40e760ec73eb515e4022670696c80a2c4085e16defe4515e40951c661eaf0a2c403995b146e2515e40b76dce77a60a2c40074147abda515e4068d201a4910a2c40d361cfe8d8515e40b24ef0a88c0a2c40f55613facf515e4015c5abac6d0a2c404ac09e65cc515e40410b09185d0a2c40decf8481c2515e401de967452f0a2c40b2f33636bb515e40eeb1f4a10b0a2c4036960bf0b8515e40dc3d8a84000a2c40b7ec10ffb0515e40d82c978dce092c40e14b3cfba5515e40e0cecf1e79092c4000cadfbda3515e40ddc4da2967092c40ed38341b9a515e40584b4bf619092c40f91400e399515e40a017ee5c18092c4078a74c7b94515e4032e9efa5f0082c400572e4dc81515e40b82d80df75082c401abe2abc70515e40979240de06082c4085bcd4be6f515e40919845cdfc072c40),
(233, NULL, 'tertiary', NULL, NULL, 'way/96321869', 0x00000000010200000046000000f1e489d6c0515e40c0153f7c4f0b2c404a720a3cc1515e40b41d5377650b2c401a02db1cc2515e406ab05f668e0b2c40199de227c4515e40bbc5b24fb60b2c40e1bf2fe4c7515e40be99e2bbde0b2c40250ffa88ce515e406b949ae2160c2c409a4af553d2515e408a9466f3380c2c40a1866f61dd515e40a3d00da8920c2c4054967c47e8515e4034e1f2b3ec0c2c407e0dd29df1515e40bf8a42812d0d2c40230fe95cf6515e4031a64f615b0d2c40602816aefd515e403324dd859c0d2c407b9faa4203525e40704f464bd40d2c40daa1abbe04525e40cee4f626e10d2c40e694809804525e403e16ecd0fa0d2c40c8ac832804525e40e109bdfe240e2c4035b401d800525e40f0e1ed9cc10e2c403b2fba6100525e40fb3f87f9f20e2c40eef0321e00525e40b0d293e81b0f2c4053e751f1ff515e405bc3561a420f2c4053e751f1ff515e40602aec585b0f2c40a125d93400525e4073be3335640f2c40a6aec62302525e40f88667ae780f2c401c5833d70e525e40fe9364c2d40f2c4000b3316516525e401f2b9db415102c40beda519c23525e40df9dc60787102c409dd7d8252a525e40615518b6c1102c40b1cae08332525e409eba4d1311112c40998eef413e525e40580ba2a476112c40330bfec83e525e40c8d7f91285112c403f15dcb43e525e40f25f200890112c40d5360f713d525e40c6ad388bcd112c4088b608313c525e4075d3c155f9112c40479968eb3b525e4048fdf50a0b122c4047263b913b525e409b351da622122c40530207593b525e40702c83c53c122c40e89903a939525e401a530b804c122c40c9ca2f8331525e402689ca2b7c122c407703bb502f525e407ac4e8b985122c40d1b018752d525e4071a719f78b122c404f1d50db2b525e4047f4215e8d122c4080208a1329525e400dbaced089122c40d427b9c326525e407fa9faf087122c40295dfa9724525e4043bf5bc587122c40eaded4511f525e401221640fa3122c40ba933e6315525e40ab3c26f7e0122c40cd9a0e5311525e402c9ace4e06132c40a6fc5a4d0d525e40a912656f29132c4092a4b5b3f9515e405f3af768bb132c4075498be9f8515e40f12fdd7fbf132c408d8ef51ef8515e40dfd8582ec0132c402970fc9af6515e40929735b1c0132c40d65d34bff5515e400e29ab8ec1132c4065636f73f4515e40466bfb0dc9132c40548b8862f2515e409219b9b8d7132c40c2397e03ee515e4057ee601ff8132c4022c15433eb515e4063cd6d6704142c401d386744e9515e40ef4adc7415142c4048478325e8515e4007c4358820142c400184b46be7515e402adfd8582e142c40251818c3e6515e405dbe9aa84a142c40f57c72b9e6515e4085fb123b64142c40549cb4bae6515e40a86d686f95142c402b06fea6e6515e40aa69728cbf142c407242322ee6515e4073e6689fd8142c40c6e70423e5515e40b1f7e28bf6142c408b000231e4515e4049545ee113152c404a9e46b5e3515e40ec0d637726152c400234000ae4515e40a86b92c437152c4067dfcb33e5515e408a39083a5a152c40),
(234, NULL, 'tertiary', NULL, NULL, 'way/96321870', 0x00000000010200000002000000e5fa2df0cb525e4042c417377f112c40ec9227ffc9525e400e1b1b704c112c40),
(235, NULL, 'residential', NULL, NULL, 'way/96321871', 0x00000000010200000023000000beda519c23525e40df9dc60787102c4074bd231928525e4043eca75a66102c40be28e6c52e525e40d8f5662f36102c4076e679cb30525e402015b5ea29102c40455ca56032525e404b3b35971b102c40874b338232525e40ce6cfc2e11102c402843fa9232525e4039622d3e05102c4063b7cf2a33525e40b3deb941fe0f2c400395f1ef33525e401c04c2f3f70f2c40ae11c13838525e404030478fdf0f2c404801fd1939525e4047a8be98d20f2c40b32781cd39525e406de92c0ec20f2c40e8ad70813a525e405498adabb80f2c406ae514d33b525e40932a9b83b10f2c401a1f1ca240525e4034304d6c990f2c409dcc898741525e407452a923910f2c405c25b3d540525e407effe6c5890f2c40030b60ca40525e403df372d87d0f2c4009f945ae40525e4040c39b35780f2c40a9633a1941525e405aa7806a720f2c404189851046525e4043e966da590f2c40162f168648525e408b08b5954d0f2c408dfd1b6a4a525e4000c80913460f2c4044bbaf6f4c525e408ed8ddf2470f2c40b25eb12b52525e4021cec3094c0f2c40e1dc15b053525e40f73aa92f4b0f2c40abf12d0755525e406060b1e1440f2c4033a48ae255525e40f140ae1e410f2c40f73deaaf57525e40c670d0b9360f2c40c2ac061761525e40bd7acb8b020f2c40e476798464525e40820ea958eb0e2c409ca73ae466525e4093286a1fe10e2c40938a6b216d525e406b28b517d10e2c40d9e841e66f525e40b26fdd83c60e2c4044d6bf907a525e4007b5dfda890e2c40),
(236, NULL, 'unclassified', 'yes', NULL, 'way/104080387', 0x0000000001020000001300000046e9770632425e408640892a57672d402e7997e631425e40a81e69705b672d401ce0939831425e4023484a1f5f672d407659a72531425e408cf2cccb61672d40523ea99b30425e406e49b31e63672d40bec6890a30425e40335f14f362672d40b80952842f425e402d324b4c61672d4083df86182f425e4094a707605e672d40a1e128d42e425e40de9387855a672d40182c30bf2e425e401bbee02e56672d403bbdf7dc2e425e4006eaded451672d4083f68f2a2f425e4043cc800e4e672d40f4dce79d2f425e408c2892544b672d404177932930425e40b0d69af749672d40ff6d60bc30425e40ecc039234a672d402eaa454431425e4098eab8d04b672d402e347cb031425e40256b1ed14e672d407b7203f431425e4023731bc352672d4046e9770632425e408640892a57672d40),
(237, NULL, 'service', NULL, NULL, 'way/118602639', 0x00000000010200000005000000237e6a61bb415e40b6c24f77f96d2d40123356f6b8415e40408864c8b16d2d401f9cf463b8415e403d36b863a06d2d406857c62bb5415e4093fc2da63e6d2d40cf424cd3b1415e408bb26d07d96c2d40),
(238, 'Magsaysay Avenue', 'tertiary', NULL, NULL, 'way/118602643', 0x000000000102000000120000005dbf057e79415e40b939f0c5726a2d409833db157a415e4054e41071736a2d40d303d5f57a415e40d105f52d736a2d40b5a272b87b415e40f6fbb440716a2d40fe4fb46183415e40323cf6b3586a2d4061ef0fa587415e40104130a2486a2d406dc5a3f988415e40e9edcf45436a2d4054dc5d0c8a415e4064daed693d6a2d40e2a47a7c8c415e405aab2cc02d6a2d403307f7b990415e40ca68893a186a2d40a08db7f097415e40acf82b09f5692d406486d73f99415e40ea2285b2f0692d4022d62ce19a415e40d3e6ee29ef692d40338001ce9c415e402098a3c7ef692d406d6468869e415e407e80fff7f1692d4073631f09a0415e40e19524cff5692d40d73cfd56a1415e40d9c00c7cfb692d40775f3a52a2415e4059cfff61016a2d40),
(239, 'Justice Street', 'residential', NULL, NULL, 'way/118602646', 0x00000000010200000005000000f4eed98445415e402ef36789df6a2d40775ac86d45415e40e7feea71df6a2d40ade3535b45415e40e1f9fb7bdf6a2d407d31a53f45415e4076e7e4a0df6a2d4093b712703e415e408783296fec6a2d40),
(240, 'Purity Street', 'residential', NULL, NULL, 'way/118602649', 0x00000000010200000004000000f52ad7802d415e40ceca51dbe16a2d400d175eee38415e405d4eaeced66a2d40891b01263a415e4082d4dcc0d36a2d408ed59c723b415e404972af82ce6a2d40),
(241, NULL, 'service', NULL, NULL, 'way/118602653', 0x00000000010200000003000000d993c0e69c415e400c1a9f6e456b2d40c257cfa4a8415e400ee3c9c91f6b2d40de4d017aab415e40716b77b4166b2d40),
(242, NULL, 'service', NULL, NULL, 'way/118603499', 0x00000000010200000005000000f5e04966d0415e407347a412436b2d40e344aaded0415e40315816f1426b2d40cf882d98d3415e401f01929f436b2d408d90cbc9d5415e4064b55439486b2d40c091e5c9da415e40e4fd13b7656b2d40),
(243, NULL, 'residential', NULL, NULL, 'way/121301382', 0x000000000102000000040000002df07096ed495e4067f3380ce6372c40c125b671fa495e40ecea44381c382c4098648973f9495e40cb1e57d92d382c4056725f18fa495e40bfc1cd9838382c40),
(244, NULL, 'residential', 'yes', NULL, 'way/121301386', 0x00000000010200000003000000ec0cf8a1f7495e4007848c367d382c4051fdde01f9495e40e6c292bc84382c40680b6366fa495e404e4d38aa89382c40),
(245, NULL, 'unclassified', NULL, NULL, 'way/121301387', 0x000000000102000000100000007aa12534ee4a5e405e746847603a2c4019e3c3ece54a5e405055a181583a2c40e186ce21df4a5e40bb1006f9343a2c40e22a0593d14a5e4005076ae7ea392c40e402869bc24a5e40e88711c2a3392c403d4e8704c24a5e40d206bbbc94392c409acbb2ccc74a5e4074c3a51941392c40d0f81972c74a5e40ee3f321d3a392c401db00683c64a5e4064d7ace930392c40124a044fc64a5e40a249bd022c392c403b0ecd86c64a5e4099c7500427392c409f1221bfc84a5e40002e122400392c4027ed574bcb4a5e40c45c52b5dd382c40a90a5751cd4a5e40c0cde2c5c2382c40efc4515ed04a5e40e087de3d9b382c40a7576f79d14a5e40426b346f8b382c40),
(246, NULL, 'residential', NULL, NULL, 'way/121301390', 0x00000000010200000006000000feff498d1a4a5e40f84d06ec0f392c401372ef2b204a5e405f7017ab17392c40ded4f6651f4a5e40de5a26c3f1382c40444717401d4a5e407ac37de4d6382c408dff4cce1a4a5e4052335afdc7382c4006088b2fff495e4096b036c64e382c40),
(247, NULL, 'residential', NULL, NULL, 'way/121328697', 0x000000000102000000040000007d4e8b0b51525e40baf1930fe60b2c40152642d94a525e40b8f589f2bb0b2c40ead6c63343525e4055072fb07d0b2c40eb3bbf2841525e409604a8a9650b2c40),
(248, NULL, 'residential', NULL, NULL, 'way/121328698', 0x00000000010200000005000000a20dc00644525e4053b0c6d9740c2c4014aa40d24c525e401536a8a21d0c2c407d4e8b0b51525e40baf1930fe60b2c40c3ac61d053525e40a2f6b6f4c30b2c40fa5ba7365d525e40adcdb51e740b2c40),
(249, NULL, 'track', NULL, NULL, 'way/121328699', 0x0000000001020000000d000000679eb70c93525e402f3201bf460e2c4066acec7195525e4086bbc4a2330e2c402fcf392e99525e40fa3d5695220e2c40d5e8d500a5525e405e7a4501ec0d2c40866d3079a8525e40ac110bc6d20d2c40311e4a59ab525e4051418f62ca0d2c403eec8502b6525e40ca17b490800d2c4039cbd188be525e4019839895370d2c40ca6c9049c6525e404b00a370e20c2c4063c3899eca525e406598c926af0c2c407dad4b8dd0525e40d6c4a7a55e0c2c401a2bd615d8525e40b9196ec0e70b2c4002733e86d8525e404030478fdf0b2c40),
(250, NULL, 'residential', NULL, NULL, 'way/121328701', 0x00000000010200000006000000a61d482847525e40693e42284a0d2c405ef5807948525e402a02f797380d2c407032607f48525e40043f051b320d2c403bc6151747525e40666a12bc210d2c40513e4ee23d525e400454ddc8e10c2c4046cd57c947525e409cd61297880c2c40),
(251, NULL, 'residential', NULL, NULL, 'way/121328702', 0x00000000010200000004000000783cd2857d525e40244d17bdae0e2c408404d6bb89525e40530ceb21750e2c403ba8c4758c525e400dd3ad8d670e2c40679eb70c93525e402f3201bf460e2c40),
(252, NULL, 'residential', NULL, NULL, 'way/121328703', 0x00000000010200000022000000fa5ba7365d525e40adcdb51e740b2c4016dc0f7860525e4003379c43630b2c40155d723763525e406f04f3a1550b2c407b489d256d525e40eedf06c60b0b2c408b93b1906f525e40a6d997c7f50a2c401cc242f776525e404f0306499f0a2c400d41c4bc7d525e4009128024910a2c4012cab1ab7f525e403862d284920a2c40bc4681f483525e4000cadfbda30a2c4032ca332f87525e40e000e951a70a2c4049032e7e89525e40f2576da3a60a2c409a65aabb8d525e4091007f42870a2c407fc97cf692525e4020e57162590a2c405f590e9997525e401ea4a7c8210a2c404babc6b79c525e404111e6d1e8092c40a36021ce9e525e4054e6e61bd1092c401a355f259f525e40dabffc5fbf092c4056229a8a9e525e40e0377469b2092c4064c8563c9a525e4090cf752b95092c402bc5e97f94525e402cfb09c270092c40f0c979b592525e40c2ebe9d962092c409781148692525e4079baa93759092c403e0801f992525e40c6be092a4f092c40b44f6caa93525e40d600a5a146092c405f590e9997525e409742d6091e092c40d8593edc9f525e40e0b3bffdca082c403419e9a0a6525e40e298c00875082c40b57867a3a9525e405699cef34c082c402bd43f2dab525e40c999dcde24082c40b4869c08ac525e40d167f62fff072c40c5782865ad525e4043d59e48e6072c40405deeddb0525e40fd1cd59fb3072c4020d3da34b6525e40aab5d5517a072c4099d30a78be525e40a2d0b2ee1f072c40),
(253, NULL, 'residential', NULL, NULL, 'way/121328705', 0x0000000001020000000400000080fbf0e233525e409268b8b7110d2c4079ea910637525e4074154152fa0c2c40c45e28603b525e40b7cdf9ced40c2c40513e4ee23d525e400454ddc8e10c2c40),
(254, NULL, 'residential', NULL, NULL, 'way/128952857', 0x0000000001020000000c00000062ef6a5efa495e40775fdf98af382c40d9dd4d01fa495e4024647b88a1382c40747401d4f9495e408ae42b8194382c40d9dd4d01fa495e409301fb438e382c40680b6366fa495e404e4d38aa89382c40678cc525fd495e40e8ba95ca80382c40426b8f28fe495e40114eb0a481382c40ee105a6a184a5e40ee015f76f4382c40feff498d1a4a5e40f84d06ec0f392c408e7b4ed5184a5e40f265fdc11b392c400c2da171174a5e4089b0863023392c4083914da8164a5e401481a09229392c40),
(255, NULL, 'residential', NULL, NULL, 'way/128952866', 0x00000000010200000002000000910e0f61fc495e40b573f5be4c372c406b3d8dc5004a5e400f81238106372c40),
(256, NULL, 'residential', NULL, NULL, 'way/128952872', 0x0000000001020000000200000044b060d1e3495e405546c8e5e4362c405a6d5919e8495e4000773469ae362c40),
(257, NULL, 'residential', NULL, NULL, 'way/128952878', 0x00000000010200000002000000166fbfd7eb495e40a0c6bdf90d372c40cc519154f0495e4023a4c920d2362c40),
(258, NULL, 'residential', NULL, NULL, 'way/128952880', 0x000000000102000000020000005df34f15f8495e4049b4893842372c40910e0f61fc495e40b573f5be4c372c40),
(259, NULL, 'residential', NULL, NULL, 'way/128952882', 0x00000000010200000002000000464f8017ec495e40fca31419c2362c4095fbd3fce7495e40395fecbdf8362c40),
(260, NULL, 'residential', NULL, NULL, 'way/128952885', 0x0000000001020000000200000083914da8164a5e401481a09229392c4062ef6a5efa495e40775fdf98af382c40),
(261, NULL, 'residential', NULL, NULL, 'way/128952891', 0x00000000010200000002000000ea11595afc495e40f59f353ffe362c405df34f15f8495e4049b4893842372c40),
(262, NULL, 'residential', NULL, NULL, 'way/128952894', 0x0000000001020000000300000055d6db0bf1495e40944a7842af372c408dcd339bec495e40f10005cd9d372c40773e4d77e8495e40e7d143238e372c40),
(263, NULL, 'residential', 'yes', NULL, 'way/128952898', 0x00000000010200000008000000d6a88768f4495e40cfe7926060382c40645a9bc6f6495e405273034f6b382c40dbb80f8af7495e402a65636f73382c40ec0cf8a1f7495e4007848c367d382c4070928bd6f6495e4068c988b086382c401708a7aaf5495e40a5c810b68e382c4006442d72f4495e40051901158e382c4054466d2cf2495e40da4823b083382c40),
(264, NULL, 'residential', NULL, NULL, 'way/128952902', 0x0000000001020000000200000055d6db0bf1495e40944a7842af372c402df07096ed495e4067f3380ce6372c40),
(265, NULL, 'residential', NULL, NULL, 'way/128952906', 0x00000000010200000002000000c30078faf7495e40861b9540ef362c408dcd339bec495e40f10005cd9d372c40),
(266, NULL, 'residential', NULL, NULL, 'way/128952907', 0x00000000010200000003000000773e4d77e8495e40e7d143238e372c40080e1e5cf0495e402fc1a90f24372c40bf38a748f4495e402dd38acae1362c40),
(267, NULL, 'service', NULL, NULL, 'way/128952909', 0x00000000010200000008000000d3ed36b9a94a5e401f73542415382c40af004b53a94a5e40c3bcc79926382c40cc800e4e9f4a5e40d2246717c2382c40401dead29a4a5e40ba23ad4214392c402f5fa80d984a5e40fc98c57a59392c40050e0d30984a5e40386a85e97b392c40536639bf974a5e40bb5a931392392c4078144262964a5e409b3bfa5fae392c40),
(268, NULL, 'residential', NULL, NULL, 'way/128952910', 0x000000000102000000030000005df34f15f8495e4049b4893842372c40e222f774f5495e40100eac996b372c4055d6db0bf1495e40944a7842af372c40),
(269, NULL, 'residential', NULL, NULL, 'way/128952917', 0x0000000001020000000200000006088b2fff495e4096b036c64e382c4056725f18fa495e40bfc1cd9838382c40),
(270, NULL, 'residential', 'yes', NULL, 'way/128952925', 0x00000000010200000003000000747401d4f9495e408ae42b8194382c40757a3947f8495e40b8af03e78c382c4070928bd6f6495e4068c988b086382c40),
(271, NULL, 'residential', NULL, NULL, 'way/128952929', 0x00000000010200000004000000678cc525fd495e40e8ba95ca80382c40c67df502fd495e4046860b2f77382c409c12b5d9fd495e40e5034c2a64382c4006088b2fff495e4096b036c64e382c40),
(272, NULL, 'residential', NULL, NULL, 'way/128952931', 0x00000000010200000004000000080e1e5cf0495e402fc1a90f24372c40166fbfd7eb495e40a0c6bdf90d372c4095fbd3fce7495e40395fecbdf8362c4044b060d1e3495e405546c8e5e4362c40),
(273, NULL, 'residential', NULL, NULL, 'way/128952944', 0x000000000102000000070000005a6d5919e8495e4000773469ae362c40464f8017ec495e40fca31419c2362c40cc519154f0495e4023a4c920d2362c40bf38a748f4495e402dd38acae1362c40c30078faf7495e40861b9540ef362c40ea11595afc495e40f59f353ffe362c406b3d8dc5004a5e400f81238106372c40),
(274, NULL, 'residential', NULL, NULL, 'way/128952945', 0x00000000010200000007000000314514eef0495e402336b3f1bb382c40a6bff27bf6495e409824e021d6382c4091370a5a124a5e40763d2c2f54392c40908df62e144a5e403e6079eb57392c40ddae3ced154a5e4017a87b5347392c40124c35b3164a5e40084cf10236392c4083914da8164a5e401481a09229392c40),
(275, 'Topaz Street', 'residential', NULL, NULL, 'way/134641790', 0x00000000010200000002000000ff209221c7425e40bde3141dc9652d4040602f5ebd425e4098a59d9acb652d40),
(276, 'Rockville Avenue', 'residential', NULL, NULL, 'way/134641794', 0x00000000010200000013000000e9bf626850425e4023cca3d1d3662d408fb97c3551425e40db8f6f4ad4662d40f330fec753425e4039c082ead5662d40498f954e5a425e40368bbc51d0662d40824de7d45f425e40b26fdd83c6662d404c4002356b425e400c811255ae662d40585e4df96b425e400d5938a4ac662d40dd99098673425e40399f950f9c662d40e8e5666e74425e40bd9d8e119a662d403315e29178425e4099620e828e662d405c5da9c27a425e409ee2827d85662d401f251bb47c425e400e057d337b662d40a27664517d425e4082a4f4f175662d404e41237d7f425e405797530262662d4070e3bb3981425e408def8b4b55662d40fe66bd7383425e408b225ae14c662d4036785f958b425e4046ec134031662d40b2aa14f18c425e40013851a62c662d4046088f368e425e406118b0e42a662d40),
(277, 'Saint John Street', 'tertiary', 'yes', NULL, 'way/134641796', 0x0000000001020000000c0000005f645d3700435e4064b95b4876672d40bea83869f5425e40f941a7316b672d402c5d667def425e40cdc17d2e64672d4005943c8dea425e409aacf6555e672d401159ff42ea425e4029dda7f45d672d405393e00de9425e4018a600625c672d40cca1a06fe6425e403e0455a357672d40a95ec834e4425e40d679afb552672d4058fc4bf7df425e40008052a346672d403ebf396dd7425e403793ca6f2c672d40f5e04966d0425e40ad5516e016672d40e3303d06d0425e4007e9ceb815672d40),
(278, 'Pearl Street', 'residential', 'yes', NULL, 'way/134641800', 0x0000000001020000000300000040fe2d5cb1425e4023bb7779df652d40f19f6ea0c0425e40b58993fb1d662d40dcda1dadc5425e406f3777aa32662d40),
(279, 'Santan Street', 'residential', NULL, NULL, 'way/134641806', 0x000000000102000000090000008a439149a1425e4059c922a875662d4037e911fea0425e409808652b79662d403d1faf51a0425e40b4c876be9f662d40ccae20729f425e4079477cddd8662d401aa88c7f9f425e4063b83a00e2662d40d26b58f89f425e406afaec80eb662d40d76dabb4a0425e40beed539ff5662d40771a1f1ca2425e405945c9f500672d407e6da23bad425e40080db38641672d40),
(280, 'Jade Street', 'residential', NULL, NULL, 'way/134641808', 0x0000000001020000000500000040fe2d5cb1425e4023bb7779df652d408d221054b2425e40cd17c5bcd8652d408d367d2cb3425e4029a380a3d3652d4080e14b97b4425e406df2a501cd652d40f60e12fdb5425e40a0ea460ec7652d40),
(281, 'Evangelista Street', 'residential', NULL, NULL, 'way/134641809', 0x000000000102000000080000006b69c93ea3425e40a2c0f16bda672d4081cd3978a6425e401c695f2f03682d40c784984baa425e4044087e0a36682d40b4869c08ac425e40017b96314f682d4066e31cd0ad425e4087808d356d682d40e2186e65ae425e40aabb0dc578682d407d224f92ae425e40ad60657e7f682d40417dcb9cae425e404a404cc285682d40),
(282, 'Gold Street', 'residential', NULL, NULL, 'way/134641811', 0x000000000102000000120000001f251bb47c425e400e057d337b662d40a33a1dc87a425e401b82e3326e662d40dac9e02879425e40d208ec2065662d40a6040eb276425e4052faf83a5f662d40911f3bb970425e4081e5ad5f55662d407e5de1b867425e40e2804c2146662d406437d8405f425e402503401537662d40352905dd5e425e40de567a6d36662d408ea2186a5e425e40fcb7dcaa35662d4044c18c2958425e4043ff04172b662d400b73ccc353425e405706d50627662d407774120052425e404bfcf61a27662d408fb97c3551425e40f2f8ac2127662d40e4d7b4f74e425e40e31ea6d82c662d4038f6ecb94c425e40d324c2d034662d404c8a8f4f48425e402a4def8744662d40946a9f8e47425e40d0e1106047662d406e4b89c940425e404518f5ff60662d40),
(283, NULL, 'residential', NULL, NULL, 'way/142564912', 0x00000000010200000002000000eb3bbf2841525e409604a8a9650b2c405ea7ec4f3d525e4060110d9c7d0b2c40),
(284, NULL, 'residential', NULL, NULL, 'way/142564920', 0x00000000010200000002000000d9710d7d41525e40c8b9a871ca0b2c4017bc43e53a525e4084995bc6f20b2c40),
(285, NULL, 'residential', NULL, NULL, 'way/142564924', 0x00000000010200000002000000bb6fc67a34525e40e968b004ad0b2c40d235936f36525e40638f9ac0be0b2c40),
(286, NULL, 'residential', NULL, NULL, 'way/142564940', 0x0000000001020000000300000017bc43e53a525e4084995bc6f20b2c403d4272d737525e40b4a4eda9e60b2c406ea46c9134525e40037976f9d60b2c40),
(287, NULL, 'residential', NULL, NULL, 'way/142564943', 0x00000000010200000003000000ecba5c693e525e40e5c06158b40b2c4017b9a7ab3b525e4088eaf70ec80b2c403d4272d737525e40b4a4eda9e60b2c40),
(288, NULL, 'residential', NULL, NULL, 'way/142564951', 0x00000000010200000008000000d8e77b574e525e402c83c53c860a2c40158a198634525e4091990b5c1e0b2c402dcf83bb33525e40d0d556ec2f0b2c40b0c7444a33525e404367e3d2420b2c4089a8d3cb39525e40e6948098840b2c4047544db53b525e40383d39549d0b2c40ecba5c693e525e40e5c06158b40b2c40d9710d7d41525e40c8b9a871ca0b2c40),
(289, NULL, 'residential', NULL, NULL, 'way/142564952', 0x00000000010200000004000000ee4dc23b2f525e40591245ed230c2c406ea46c9134525e40037976f9d60b2c40d235936f36525e40638f9ac0be0b2c4047544db53b525e40383d39549d0b2c40);
INSERT INTO `streets` (`Id`, `Name`, `Highway`, `Oneway`, `OldName`, `StreetId`, `Geometry`) VALUES
(290, NULL, 'residential', NULL, NULL, 'way/142564957', 0x00000000010200000004000000bb6fc67a34525e40e968b004ad0b2c40025b6fe536525e40846973f7940b2c40e99c9fe238525e40a822707f890b2c4089a8d3cb39525e40e6948098840b2c40),
(291, NULL, 'residential', NULL, NULL, 'way/142564959', 0x0000000001020000000200000041d653ab2f525e40d26cc3cd4e0b2c40025b6fe536525e40846973f7940b2c40),
(292, NULL, 'residential', NULL, NULL, 'way/142564964', 0x00000000010200000006000000ead6c63343525e4055072fb07d0b2c40abbaa2ef49525e4036125784510b2c402ef87eb449525e4055db4df04d0b2c4082fc112b48525e40ce42f1193f0b2c40a0a28f9e47525e40a1a2ea573a0b2c40eb3bbf2841525e409604a8a9650b2c40),
(293, 'Holy Cross Road', 'unclassified', NULL, NULL, 'way/176156455', 0x0000000001020000000200000046e9770632425e408640892a57672d402411757a39425e409c5c42f45a672d40),
(294, NULL, 'residential', NULL, NULL, 'way/178310966', 0x00000000010200000002000000f09aa102f1415e40bec4b35fd26b2d4079c663abf0415e40edda3928bc6b2d40),
(295, 'Barangay San Bartolome Road', 'tertiary', NULL, NULL, 'way/195521210', 0x0000000001020000001700000004615dcb9a4a5e40e9dc4834dc372c4015f7c4df9b4a5e402d019deee1372c40975643e29e4a5e40eac6606af0372c4053e2df0ca34a5e405c60ea4207382c405ee68585a44a5e40d1cc936b0a382c4022f6aee6a54a5e4039c7ca7910382c40f870c971a74a5e402c55585f13382c40d3ed36b9a94a5e401f73542415382c40f045c549ab4a5e4090d2116514382c4089e4750eaf4a5e40cdf9731b1e382c40827a8e23b14a5e404dc0af9124382c40459e245db34a5e40205d6c5a29382c407f96f8edb54a5e4000bc4f9f2e382c4037dec25fb84a5e40da1544ee33382c4016e1815cbd4a5e4041e5a95846382c40452e3883bf4a5e40ccdd9d6b4e382c4067576b72c24a5e408021f5e857382c40183b866cc54a5e406f97a20161382c408eaacbcec74a5e4035eac6606a382c4052baf42fc94a5e40af8339306f382c406fe4709cca4a5e40caccbba074382c40b46a2112cf4a5e40167b794b83382c40a7576f79d14a5e40426b346f8b382c40),
(296, NULL, 'residential', 'yes', NULL, 'way/217822643', 0x00000000010200000003000000407edbb8ea415e40c2df2f664b6a2d40bb760e0aef415e40c669882afc692d40c1d72148ef415e4068812cfaf9692d40),
(297, NULL, 'residential', NULL, NULL, 'way/217822645', 0x00000000010200000004000000564f41d9ef415e40062f55c4446a2d4083908719f5415e40b155dd7e546a2d40ffdce1c0f5415e40d3c32ba4576a2d40524e6a1ef6415e40962941da5a6a2d40),
(298, 'North Point Street', 'residential', NULL, NULL, 'way/217822646', 0x00000000010200000002000000583c5002f6415e402299c40f846a2d4077fc72c1f4415e40792288f3706a2d40),
(299, NULL, 'residential', NULL, NULL, 'way/217822650', 0x00000000010200000004000000f640d076f1415e40b1998ddf256a2d40553b7947fc415e40b7f52e39496a2d40d214a694fc415e406ee1d4624b6a2d40254113bcfc415e40379490fe4d6a2d40),
(300, NULL, 'residential', 'yes', NULL, 'way/217822667', 0x0000000001020000000300000085155dcdf0415e404e27d9ea726a2d4051398144ee415e4074684760626a2d40407edbb8ea415e40c2df2f664b6a2d40),
(301, NULL, 'residential', NULL, NULL, 'way/217822668', 0x0000000001020000000400000051398144ee415e4074684760626a2d40564f41d9ef415e40062f55c4446a2d40f640d076f1415e40b1998ddf256a2d40c5e40d30f3415e40920953ef046a2d40),
(302, NULL, 'residential', 'yes', NULL, 'way/217822672', 0x00000000010200000006000000254113bcfc415e40379490fe4d6a2d40de4f32defb415e40a13e13ab506a2d40524e6a1ef6415e40962941da5a6a2d406b20a7f9f4415e40e84f768e5c6a2d407d321015f4415e40abb58bc45f6a2d40a20e2bdcf2415e4085c7c8a3656a2d40),
(303, NULL, 'residential', 'yes', NULL, 'way/217822673', 0x00000000010200000004000000c1d72148ef415e4068812cfaf9692d40fc06dca9ef415e401bd0775cf9692d40c5e40d30f3415e40920953ef046a2d40d2e3f736fd415e405706d506276a2d40),
(304, NULL, 'service', NULL, NULL, 'way/217822675', 0x0000000001020000000a0000004496bb85e4415e408a5352cce66a2d403f3e7cf4e1415e40f0d302c5d96a2d4028e84020e1415e40accf8bc9d16a2d40ce9fdbf0e0415e4093ee9d87c96a2d40ec2bb418e1415e40b53f06e1c06a2d40c8df0731e1415e4029df7d9fbb6a2d40fe37e5c0e1415e40cb21f312ad6a2d40673e8cb5e4415e40b961ca76746a2d4084680822e6415e4047c8409e5d6a2d4071af2715e8415e4039df3e613f6a2d40),
(305, 'Golden Peacock Street', 'residential', NULL, NULL, 'way/222731620', 0x00000000010200000002000000f2fadd8577425e4083609f4a17682d4067f915c671425e40eadf3f27ce672d40),
(306, 'Blue Bird Street', 'residential', NULL, NULL, 'way/222731625', 0x00000000010200000006000000c089326571425e4048abb58bc4672d40c4c4307175425e40bae2981bc2672d40da25057179425e4005eff5ffbb672d406170cd1d7d425e408eb51a6db0672d406bf8718f80425e407b698a00a7672d408eb74bd180425e406a32e36da5672d40),
(307, 'Orange Street', 'residential', NULL, NULL, 'way/243497961', 0x00000000010200000009000000b73874c4eb415e4061d74004666b2d40a3ec889eef415e4028f796cd776b2d40cc37ec08f1415e401fdac70a7e6b2d407805476ef2415e40c99bb289826b2d40896a0025f4415e40cda89e71866b2d40888f3e9cf6415e401eaff6668a6b2d40e45421d4fb415e40805c870f916b2d404e6f35a1ff415e4042322e66956b2d408552c59e07425e402d7b12d89c6b2d40),
(308, NULL, 'footway', NULL, NULL, 'way/243498008', 0x00000000010200000006000000866f062406425e40b6c7c15bd66b2d409081e1010a425e404f0a4ed8d96b2d4070e360800e425e40b3afe18edc6b2d400731862815425e401c12adcbdf6b2d40b38bb33316425e408e29b39cdf6b2d4036502a2b17425e40caeb7717de6b2d40),
(309, 'Gozum Street', 'residential', NULL, NULL, 'way/245591357', 0x0000000001020000000200000025f6bf12fe415e408bcc1253d86b2d40eafa4f48fc415e40b83d4162bb6b2d40),
(310, 'Gozum Street', 'residential', NULL, NULL, 'way/245591358', 0x00000000010200000006000000eafa4f48fc415e40b83d4162bb6b2d40b5d084dcfb415e40eb7d99deb46b2d409111ab9afb415e404d56fb2aaf6b2d400e61a17bfb415e4027dbc01da86b2d4032db5f87fb415e409b0aa7bba16b2d40e45421d4fb415e40805c870f916b2d40),
(311, NULL, 'service', NULL, NULL, 'way/262543706', 0x00000000010200000002000000cca266fe07425e40565e978686662d4031dea00708425e4097303fdc7a662d40),
(312, 'Makiling Trail', 'path', NULL, NULL, 'way/271599799', 0x000000000102000000e30000000ce71a66684c5e40e27327d87f452c401fa397ac654c5e403d27bd6f7c452c40b09a9dfb614c5e406312899d84452c4024c44b265d4c5e40ab31d75878452c40670a9dd7584c5e40436271ee65452c40e02f664b564c5e40f9c89c1d5f452c40d6aa5d13524c5e40547c32b55b452c401af1aec44d4c5e40547c32b55b452c40f89969b14a4c5e400b20216f5e452c400b56e6f7474c5e401c3ae23554452c40065acbae454c5e4091f936b34c452c404f290a4f434c5e405ab7e63345452c40df066b52404c5e40115bd5ed47452c40da9722af3d4c5e406bd1a7fa3a452c40a01518b23a4c5e40a84eacf82b452c404ec1d0d9384c5e40ccfcb49b2a452c40e4ce96bd364c5e40ccfcb49b2a452c405cf45f31344c5e4027b04a3327452c40dabcbbdf324c5e40cbbff11021452c4058f844e8314c5e402536c41d14452c4023ff27da304c5e40d1faa58f0a452c400531d0b52f4c5e402536c41d14452c40362ed27a2e4c5e40a711e96d22452c4031a5e48b2c4c5e408363e0ca23452c40c625d8c92a4c5e406fcf98ee1a452c40f2b391eb264c5e404b21904b1c452c4005e33b8c244c5e40388d486f13452c4061e124cd1f4c5e4080e959b510452c40bc523b681b4c5e4086240e34fa442c404d4a41b7174c5e40a995534cef442c40cb85cabf164c5e40d4bbd3f8e0442c40dece19ac134c5e409eb64604e3442c40d9b85917124c5e40973ecffaef442c409f364f1a0f4c5e4062760591fb442c40b2f2cb600c4c5e40c3a11232eb442c40adf6b0170a4c5e4011fc146cc8442c40d4e1d7fe044c5e40fd67cd8fbf442c4065f38299004c5e40905db3a6c3442c402be4a5f6fd4b5e40905db3a6c3442c40515c9f83f84b5e40fd67cd8fbf442c40c5122054f34b5e407e062f55c4442c409e32ed51ee4b5e408f20f01bba442c40acf24e4fe94b5e40e996c228ad442c40552fbfd3e44b5e40fc2a0a05b6442c40c4e9245bdd4b5e40fea4901ac9442c401b5f20add64b5e4039a80e03a7442c405f189fb8d24b5e40808a993391442c40a75a0bb3d04b5e40bd079e3182442c405a8fb1c9d04b5e40cde49b6d6e442c4077d03648d24b5e408ac33ea65a442c40a7406667d14b5e40acf7c03346442c40d73d682cd04b5e40319413ed2a442c40f40bc050d14b5e4037cfc76b14442c40d73d682cd04b5e403d0a7ceafd432c40ef82d261cf4b5e40719582c9e8432c4068c24021cc4b5e4050a8a78fc0432c40b004ad1bca4b5e408ce8e802a8432c407b7ebd67c94b5e40ee13f6a397432c4046f8cdb3c84b5e406c38d15389432c4033c92313cb4b5e40e0ba624678432c409dd5027bcc4b5e40cd261b6a6f432c40a2d11dc4ce4b5e40df7d9fbb6e432c40a75a0bb3d04b5e404dc57c2f74432c40764364a2d24b5e4039f471c861432c40f47eedaad14b5e401bbee02e56432c4042d7193ad14b5e40230e7e8747432c4019bac8f3cf4b5e40bd5301f73c432c40bf85d09cd04b5e40cb1b165921432c40d0775cf9d14b5e4089377c1c17432c4052af004bd34b5e408e356d10f7422c40d5e6a49cd44b5e40f7b0170ad8422c40689da7f0d64b5e40e31cd02dcf422c4055545804da4b5e40b5a4a31ccc422c405ff30588dd4b5e405127ea16cb422c40f28f6390e04b5e40f53691f4c4422c40ebafb211e34b5e4059b44afac5422c40e45cd438e54b5e40ab9dbc23be422c40d113854ce84b5e4054e81780a1422c4058d4168deb4b5e4012047e4397422c40101f7d38ed4b5e40083a5ad592422c404a2e5adbef4b5e40468f842282422c40c0fc5fbff14b5e403dc560b47d422c402a093f27f34b5e40889bf80f8e422c40fa7e6abcf44b5e40f6e2d58393422c40ca0e3b9df54b5e40c72de6e786422c40a6ed04a0f64b5e40e211cb1c81422c405d386b4bf84b5e406928a4eb78422c4097ba7548fb4b5e40f4d7d07245422c405be1a7bbfc4b5e4071e7c2482f422c408b51d7dafb4b5e408a8ee4f21f422c40d420167bf94b5e40e42c91b014422c400491459af84b5e40030f67d9ee412c40b256a30df64b5e40304ad05fe8412c40648b4924f64b5e40dad1ee46d5412c4081cccea2f74b5e40358584ded1412c40c32e8a1ef84b5e40d0ca074ec7412c40757dd580f74b5e403a8375d2b1412c40b752be56f84b5e408a2f2471a0412c40ca0e3b9df54b5e400fcc762a85412c40ca9b0d43f54b5e40834e081d74412c40be326fd5f54b5e4066f09cd266412c40893952c7f44b5e403ff0e7ca56412c403bfbca83f44b5e40fca6b05241412c40ad5a88c4f34b5e407af365b334412c404fb747caf14b5e400a6fc5b425412c409e4c929ded4b5e40d86729b407412c4064b0e254eb4b5e40dea2dd32f1402c40776c5f9be84b5e401cf80780e0402c40778604e7e74b5e409a44bde0d3402c409604a8a9e54b5e40e8db82a5ba402c40d36a48dce34b5e402631adf2a9402c40cee15aede14b5e4011887c3c99402c4081a3d3a9e14b5e40bd2484fd8d402c40fe6b2f58e04b5e4033bcfec984402c40c972124adf4b5e4079c663ab70402c40aca4ba25de4b5e40b64368a961402c40838769dfdc4b5e4063e06f6a56402c409b3f016fdc4b5e404e0f650344402c40ccc9d5d9da4b5e40f009230736402c40de6badd4d84b5e40382971c229402c4027ae19cfd64b5e401af3df281e402c40fe90c888d54b5e40634ff16e1b402c408835f0fed34b5e408f4d976a0b402c408503c69fcd4b5e40c6c1a563ce3f2c40507dd6ebcc4b5e40307a13e8b83f2c40500aa991cc4b5e40480c4cb8a13f2c40c665811bce4b5e40fd35b45c913f2c40616f6248ce4b5e40ba1457957d3f2c40deaaeb50cd4b5e4026e2adf36f3f2c40749e0ce9cb4b5e40d567bdce3c3f2c40333c516dcb4b5e408eb7f0170e3f2c409dd5027bcc4b5e4012178046e93e2c40d2414de3cd4b5e4071c806d2c53e2c40b500c864cc4b5e40f7a11c16b43e2c40b58d9a0acc4b5e40be22090ca33e2c40684f13c7cb4b5e4073744b61943e2c40cdb85ff4cb4b5e40e7ce02a3813e2c408c7049c4ca4b5e4077723c55743e2c4022d797b6c94b5e4011b8bfc4693e2c4087e75bd5c84b5e40618c48145a3e2c40abeeec86c84b5e40ce9662fd553e2c40d09cf529c74b5e40853a51b7583e2c40eaab5049c24b5e40dfb023c44b3e2c40a4c0a7debf4b5e40bb021b214d3e2c402969b40bbc4b5e40d39453f1353e2c40488ecfbfb84b5e40bf000c152d3e2c40f63988e7b64b5e40212c19b61c3e2c4098231a93b44b5e409686d0f7093e2c406f06c94cb34b5e40e55a5947fa3d2c4099881288b24b5e40fed6a94df73d2c40823573edb04b5e405bf2d313f13d2c407dac85feae4b5e40c06f8d19f23d2c401f9617aaac4b5e402eb76a8df73d2c40a8209ad4ab4b5e4038818efbfb3d2c4090680245ac4b5e4043609b43083e2c40b9122631ad4b5e406a882afc193e2c40b23275b2af4b5e4049699148363e2c40be9b1320af4b5e404cbb3dad473e2c40f32103d4af4b5e4073e3cc65593e2c409aed0a7db04b5e40183037ce5c3e2c4082a8a047b14b5e401cbfa6bd773e2c40e0d8b3e7b24b5e40b1c975ae833e2c40fda60b0cb44b5e4073744b61943e2c404046e5cbb04b5e406cfcd357a13e2c40caea0c42af4b5e406232b0e99c3e2c4030fbd060ae4b5e40c59a8015963e2c4037c1dc93ac4b5e4085cbcfb2933e2c4062c2c30fa94b5e40077f1a52a03e2c4086562767a84b5e40d2b650e8ab3e2c40c845b588a84b5e40e54a98c4b43e2c401cd71aa5a64b5e40aed689cbf13e2c40450e1137a74b5e40678f615ffc3e2c404f458545a04b5e407a23a93b053f2c40eb8b84b69c4b5e40bbf2599e073f2c40a52daef1994b5e407b606cc60e3f2c40c5c5f6ff964b5e404de83fb50b3f2c40b3d36aa3954b5e400d198f52093f2c400d7b9054954b5e404770c8ab183f2c40f0c6dd7b934b5e4092466007293f2c4020c4df40924b5e408bcee8fd353f2c40b6b700d9904b5e4014faaaa6353f2c401b3bf251904b5e40c0be8c182c3f2c40b1bbe58f8e4b5e40c84bedfb263f2c40fafd518a8c4b5e4049ea4ec12b3f2c4072231bfe894b5e40dcdf34d82f3f2c407e198c11894b5e40c0be8c182c3f2c40ba6587f8874b5e4077627bd22e3f2c4020764b17874b5e40c0be8c182c3f2c40c2d20a1d854b5e40e46c95bb2a3f2c40bd491d2e834b5e40f5865682203f2c4088c32d7a824b5e40c4bc7d0c0c3f2c40426557b57f4b5e40c242f7f6f83e2c4007c9a76c7d4b5e40643db5faea3e2c406170cd1d7d4b5e40ac5c03b6de3e2c40deab56267c4b5e40bc9e9e2dd63e2c409dd66d507b4b5e4005fbaf73d33e2c4068dd50427a4b5e401615713ac93e2c40fe5d4480784b5e40f9b605f0bb3e2c4093516518774b5e40895a3fa2ae3e2c40dc792cc7754b5e40056a3178983e2c401f33abd2714b5e4011b8bfc4693e2c40687517cd6f4b5e40eab70abd593e2c40d9d4d40d6f4b5e4073e3cc65593e2c40e0b4858c6c4b5e4077e1bd59393e2c409376fe486c4b5e4089fb7e202f3e2c40763579ca6a4b5e405831a6aa1a3e2c4041af89166a4b5e402ff42d18013e2c40655d92b9684b5e40b7e22c36f73d2c40be77e5c4684b5e40e208ade2e83d2c40481c0d3b674b5e4029eb3713d33d2c4013961d87664b5e407032607fc83d2c40f6549808654b5e405411b8bfc43d2c4073034f6b644b5e4002284696cc3d2c40fd1aa43b634b5e40d6c4025fd13d2c406f073422624b5e4027d64e39cb3d2c406f9406c8614b5e4037b34c75b73d2c408e9f7c305f4b5e4070a1e1838d3d2c40b2c0b22d5e4b5e40659afa8a7f3d2c4059a65f225e4b5e4077b4bb51753d2c4024ad42145d4b5e40759fd2776d3d2c40a1e8cb1c5c4b5e40597e2ab8693d2c40dec199a95a4b5e4097d35405593d2c40374f1a0f5b4b5e405d7c1bac493d2c4073b5ba41594b5e40f8c19e1b3f3d2c40a43f8fac574b5e40f8c19e1b3f3d2c40217b18b5564b5e40912ffc3b363d2c4051781a7a554b5e40912ffc3b363d2c40),
(313, 'Mount Makiling Sipit Trail', 'path', NULL, NULL, 'way/288598492', 0x00000000010200000071000000eec5617a0c4c5e401ff46c567d362c40d0dac8d00c4c5e4016acccef8f362c405e4df96b0d4c5e40c8cf46ae9b362c4011e15f040d4c5e40341f2114a5362c40edbf29070e4c5e40e335afeaac362c40b705f0bb0e4c5e40e95784acb8362c40581af8510d4c5e408a4457d8c2362c40be5b6ace0b4c5e409a95ed43de362c40fa2e00e80b4c5e408f801b73e8362c40addc0bcc0a4c5e40214b30e6f8362c400deb7c2e094c5e402b7af18f08372c40e5b9be0f074c5e405b24ed461f372c40e5b9be0f074c5e40500f1b7629372c4086cec6a5054c5e40c280ca9d3e372c403349d16f044c5e406060b1e144372c403349d16f044c5e409b1f7f6951372c40c9e0cdbf024c5e40d9f62cbe57372c40c3de7a03024c5e40649c757c6a372c4005e51137024c5e40b49fd67e7c372c40356c4a68014c5e40aec6c848ac372c4047228f3b004c5e40b0eda309ca372c4006088b2fff4b5e4054ef5f0fdc372c403e5ea340fa4b5e40be9de9ca0c382c40ab2006baf64b5e40a22aa6d24f382c404145d5aff44b5e4063e4767984382c4005589a4af54b5e40cf3351df8d382c402a37514bf34b5e409413ed2aa4382c409c2045f8f24b5e40714ffcbdb9382c402a937593f34b5e40f3e2699ec8382c4036dfd27bf44b5e40a85c97d013392c409afdcbfff54b5e402e2cc94b48392c404b6eb99ff84b5e4002d8800871392c40453bb885f84b5e4043b9235289392c40a426b0eff94b5e40ce7b52dca7392c40749f77befa4b5e40e9e1ba18b9392c401be7806ef94b5e4066683c11c4392c4015b47f54f94b5e40ab56cb42e0392c405ded17a2f94b5e40e1229cbb023a2c4097fcf444fc4b5e4099034e000f3a2c4014ababa7fb4b5e4027fb4223333a2c40317903ccfc4b5e4058c51b99473a2c4079a1ca7afb4b5e40f8d6d182613a2c400f22beb8f94b5e402edc5e775f3a2c403a96d28ef64b5e40661eaff6663a2c40a0a696adf54b5e40e1815c3d823a2c404e524fd5f34b5e40ed6069858e3a2c40b3d5404ef34b5e4093ea96789b3a2c409694bbcff14b5e4088742e7bc83a2c409694bbcff14b5e40bbb88d06f03a2c40145d177ef04b5e40116e32aa0c3b2c4044e7ebe8ee4b5e405b07077b133b2c403fd12b54ed4b5e40b6ba9c12103b2c4083177d05e94b5e40b17fe893263b2c40b387ac24e84b5e4098b0ec38343b2c404e918d51e84b5e403e3a1a2c413b2c40fb3c4679e64b5e40cbf44bc45b3b2c40fbc9181fe64b5e40fdfbe7c4793b2c40c643296be54b5e4023e7b3f2813b2c407e8e8f16e74b5e4030404750a13b2c4019987043e74b5e40a9296e81a93b2c40aefebe35e64b5e40b6453e54bf3b2c40c643296be54b5e40ee878ed3c63b2c4061c037f2e54b5e40b1474d60df3b2c4019987043e74b5e407644cf77013c2c40e311818fe64b5e40652a0eb10b3c2c4019987043e74b5e40afc3e281123c2c40487bcdbce64b5e405fb296a7183c2c4019987043e74b5e40bcdfb254283c2c4096b95400e74b5e40dc8fca03473c2c4061c037f2e54b5e40bd851a2a6b3c2c4096d3f94be64b5e401cf0f961843c2c404908a062e64b5e4083bf5fcc963c2c40614d0a98e54b5e40fe220d13b23c2c40e384aee9e64b5e40f8aa9509bf3c2c40cb3f44b4e74b5e4055d8b1b6ce3c2c4065bc523be84b5e400db963fbda3c2c401d07b9e6e94b5e407588c965ed3c2c407604cb6ceb4b5e401062c2c30f3d2c40ab2e96d8eb4b5e40e4abd3371f3d2c40ed9689c7ea4b5e40d9960167293d2c404d04bbabe84b5e40d9960167293d2c4000c63368e84b5e40afad4445413d2c40440c8519e44b5e40665133ff433d2c40c1ba3b7ce34b5e4029d42e01533d2c4027cbff9ae24b5e4018ba6d3a5d3d2c40bc314e8de14b5e40b68e60996d3d2c40f1b73d41e24b5e40eed0b018753d2c40d07a9d79de4b5e406d324f53703d2c4096f8927cdb4b5e40a5749fd2773d2c40ec6d8eced44b5e40da3c693c6c3d2c409aa6199cd24b5e40d09a1f7f693d2c4043e38920ce4b5e40e1b4e0455f3d2c40f11b15eecb4b5e40cf5d5cf45f3d2c40569f0667cb4b5e4019f730c5663d2c40569f0667cb4b5e407f89d3a46f3d2c40395e81e8c94b5e40f4482822683d2c40cac8b491c64b5e40aaaf5351613d2c402b508bc1c34b5e404ffcbdb9643d2c40c0d07effc14b5e40e2f1a3d0683d2c4009f945aec04b5e40d09a1f7f693d2c40864e7402bf4b5e406d324f53703d2c40b7bea321be4b5e40127fb9bb733d2c404ccc6905bc4b5e40a6b1625d813d2c402ffe11e1ba4b5e40d77b3bd3953d2c402ffe11e1ba4b5e40a2b37169a13d2c4012bd8c62b94b5e401bda5b25b33d2c40fa04f5d2b94b5e40e61192bbbe3d2c402ae8514cb94b5e403a4db049c83d2c405ae55311b84b5e40a9948dbdcd3d2c40c082ead5b64b5e40f32d628ed43d2c400dc17119b74b5e40c707e2e1e23d2c4004af963bb34b5e406d910fd5ef3d2c4099881288b24b5e40fed6a94df73d2c40),
(314, 'Luck Street', 'residential', NULL, NULL, 'way/330473351', 0x000000000102000000020000008068418328415e40ac61759abb682d40333674b33f415e407a6ddb9cef682d40),
(315, 'Generous Street', 'residential', NULL, NULL, 'way/330473352', 0x000000000102000000030000003ca1d79f44415e406a036674f6682d404c5fbeab54415e40adb13a2817692d40fb05bb615b415e407cce82f524692d40),
(316, NULL, 'residential', NULL, NULL, 'way/348674014', 0x00000000010200000008000000cd70a8844c4a5e40d358b1aec0362c40c01b77ef4d4a5e402b72e371ac362c406c17e4784f4a5e40555ba09394362c404208c897504a5e40c9dd318683362c408f15a17d514a5e408981093774362c4059ce948c524a5e4065b61ac869362c4034c1cb67544a5e40d910d20957362c40fe79bf76554a5e40b3a08be145362c40),
(317, NULL, 'residential', NULL, NULL, 'way/348674028', 0x0000000001020000000a00000057f9afbd604a5e40fdb90d0f06372c40baac78d9654a5e402280e552a6362c4093a7aca66b4a5e404f8b660a42362c4039cc3c5e6d4a5e40762277c718362c405c435f306e4a5e40fcfb8c0b07362c40098783296f4a5e40d5438f73f6352c40bbb88d06704a5e40cb31b495f2352c40ae60c037724a5e40a663ce33f6352c402f5ee27e764a5e406bc1e677f5352c40095f4ebf7a4a5e40b262b83a00362c40),
(318, NULL, 'residential', NULL, NULL, 'way/378411848', 0x00000000010200000015000000bb6fc67a34525e40e968b004ad0b2c40cf00cdd630525e4090c6fc378a0b2c405a24928d2c525e402f52280b5f0b2c40c784984b2a525e4090edc6cc4f0b2c409893066d28525e4084c60215440b2c406ad322ec25525e40ce250b4e330b2c40bafb77d81f525e404a062571fb0a2c40f86d88f11a525e4023145b41d30a2c409cf3f86214525e40e708cf3a990a2c406e36b11b11525e4082ecab61750a2c40b6e512fd10525e4093beb5b86b0a2c408438c59915525e408ef2823e470a2c40c2267c001c525e40e89e1ad4230a2c40af5692e11d525e4060be068e150a2c40681a5e5a1e525e40fa731b1e0c0a2c40379089ef1f525e4082621a3c020a2c400c8fa27323525e40991c2dbdec092c40877368ec26525e40caba2473d1092c409d610f922a525e402ba96e89b7092c40bf2b82ff2d525e4079680eff9f092c4082aed8ba2f525e40d5ae09698d092c40),
(319, 'New Jersey Village', 'residential', NULL, NULL, 'way/393587021', 0x00000000010200000009000000ad5ffaa8d0415e402cd3d457fc6b2d401d8535dfd2415e4023c4f06cea6b2d406a1fe16ad3415e4030a6f4a7e86b2d4052ac6411d4415e4005f3fc0eea6b2d40d5cf9b8ad4415e4004d31f50ec6b2d4086151340d6415e40198744ebf26b2d40e6a7829bd6415e40fa25e2adf36b2d409278793ad7415e40259122d7f26b2d4032f7da7dd8415e40fe3dc27aed6b2d40),
(320, 'Mulawin Street', 'residential', NULL, NULL, 'way/393587022', 0x0000000001020000000300000084ec61d4da415e40d83c5810146d2d401f9a1eb9da415e409555c7e0176d2d405c7cc0f2d6415e403e26ad53406d2d40),
(321, 'Mangga Street', 'residential', NULL, NULL, 'way/393587023', 0x0000000001020000000600000046072461df415e404cd8c8bfe06c2d4079ce1610da415e4094957032bb6c2d40689a0bb7d7415e40a7a73407ad6c2d4034d53840d5415e408b91802c9f6c2d408e290e56d2415e406199c816936c2d4025f8f076ce415e40859a7c0e876c2d40),
(322, 'Barangay San Bartolome Road', 'tertiary', NULL, NULL, 'way/419363601', 0x0000000001020000001b000000a7576f79d14a5e40426b346f8b382c402fc214e5d24a5e4039268bfb8f382c40a4d299c5d54a5e40b0cff7ae9c382c40ceefea0bd74a5e40e8a1b60da3382c40a3c629dfd84a5e403be5d18db0382c4007e52263da4a5e409a0af148bc382c405aac9795dc4a5e40cd84155dcd382c40820b68d8de4a5e4011c64fe3de382c40bd659824e04a5e40a6d01ed4ea382c40d4b837bfe14a5e4046555dd1f7382c40a4bb35fae24a5e40b2eceea600392c4044dbd6bbe44a5e40ee83e27d0b392c40d87d6c37e64a5e40f69dba4d13392c4095fbd3fce74a5e402d509ced1b392c40416a6ee0e94a5e40f7f763a428392c407016e588eb4a5e408a52e7f637392c402e3bc43fec4a5e409799886d41392c40b6ed201bed4a5e40e9047e9e50392c400900e9f6ed4a5e403e7d5fb763392c401b7f47f9ee4a5e40551e937b70392c40bbcf9618f04a5e40e61b768478392c4084995bc6f24a5e40b74da72b8e392c4017a9e628f64a5e40b834c86eb0392c406a6226f6f54a5e409db58075c1392c40a6f0a0d9f54a5e40d67c4befd1392c401d7d27c1f64a5e40310510e3da392c4069a109b9f74a5e40b0cb4b59e1392c40),
(323, NULL, 'unclassified', NULL, NULL, 'way/419363602', 0x000000000102000000040000007aa12534ee4a5e405e746847603a2c40b43a3943f14a5e40af06280d353a2c40c5f87a08f44a5e403366b73b103a2c4069a109b9f74a5e40b0cb4b59e1392c40),
(324, NULL, 'service', NULL, NULL, 'way/419363603', 0x000000000102000000060000007aa12534ee4a5e405e746847603a2c40387e4d7bef4a5e40a975d146643a2c40f030ed9bfb4a5e4078149d1b893a2c406eba0ace054b5e4018265305a33a2c406c7dec89094b5e407416ac27a93a2c40715f62870c4b5e4011aedbfbaf3a2c40),
(325, NULL, 'unclassified', NULL, NULL, 'way/419363605', 0x000000000102000000060000004f5f2a911f4b5e406517b1f4463a2c406cb41ce8214b5e40f92180e5523a2c407d19d69e234b5e407cd5ca845f3a2c406a357fa7244b5e40d0c831a3693a2c403a52222e254b5e40a2fd593d713a2c4052f01472254b5e4040958911783a2c40),
(326, NULL, 'unclassified', NULL, NULL, 'way/419363606', 0x0000000001020000000600000052f01472254b5e4040958911783a2c4022f312ad264b5e40745a5c887a3a2c4057be1d97274b5e406a4881aa763a2c40f1683e42284b5e40400812256b3a2c4057be1d97274b5e40aff83c354d3a2c403a07cf84264b5e40e82e89b3223a2c40),
(327, NULL, 'service', 'no', NULL, 'way/451675114', 0x00000000010200000006000000241411b438425e400805a568e5662d40b47570b037425e40c0102851e5662d401fa22cd736425e40b4064a65e5662d40e770adf630425e4007bdedf8e5662d40ad1f51572d425e40258ee156e6662d404ceb257c25425e40488c9e5be8662d40),
(328, NULL, 'service', 'yes', NULL, 'way/454799924', 0x0000000001020000001500000065ff3c0d98495e4006723f96f4362c40168acff899495e4085d3ddd0ef362c404c6ce3f49a495e40b0164449ed362c40bc804d8c9b495e4046dc52bdeb362c4098480e7d9c495e40711fb935e9362c40b09e49519d495e4096157948e7362c403896c1629e495e4062985d41e4362c40914eb8b29f495e40d5a76620e0362c40b3d9475da1495e403cf54883db362c4095bd0056a2495e40fc259820d9362c406b97db62a3495e409880046ad6362c40be05c886a4495e40e124cd1fd3362c402db29defa7495e40b14f00c5c8362c401a3ed818aa495e409191fd3dc2362c40d8bb3fdeab495e40db0dec42bd362c40420d3a7cad495e40cb3ed9deb8362c40418e9c3bb0495e40f34c79beb0362c4027b627edb2495e403fc16ad1a7362c40e519ea66b5495e40521be61599362c40a9cdee7fb6495e40ca62ac808c362c40ea18a1e9b6495e408279234e82362c40),
(329, 'Makiling Trail', 'path', NULL, NULL, 'way/455442522', 0x0000000001020000002e00000051781a7a554b5e40912ffc3b363d2c40e9352cfc4f4b5e408765d8cd313d2c40aab706b64a4b5e409ff7109e1a3d2c402f6013e3464b5e4026a94c31073d2c402a4a534e454b5e40ec5113d8f73c2c40662321db434b5e402992544bdf3c2c40e4784f2f424b5e407a7bc674d73c2c40bbce2b43414b5e40a7b62ffbd03c2c40bbce2b43414b5e409422e81ec83c2c40340e9a023e4b5e406be56f8cae3c2c40ed951ef23b4b5e40fcc56cc9aa3c2c40e89903a9394b5e4060066344a23c2c4000529b38394b5e4043a8f7f9943c2c40773a46683a4b5e401ba842f2843c2c40c405a0513a4b5e40c8444ab3793c2c4072b15879384b5e407c968c086b3c2c40f079b427374b5e400c12ec095c3c2c408a839554374b5e40b7990af1483c2c40614c9fc2364b5e40a405c314403c2c40a98e0bbd344b5e405857056a313c2c402241a7d6314b5e407bc84a82263c2c401dd25e332f4b5e4026506969133c2c404ecf60f82d4b5e40a5b107a40e3c2c4024253d0c2d4b5e40921dc0c7053c2c405aab2cc02d4b5e407eb1529cfe3b2c40cb7d175b2d4b5e400e2db29def3b2c406687f8872d4b5e40a972350de53b2c40c6f4296c2b4b5e404b6df310d73b2c408c8cc4ba274b5e40f709fbd1cb3b2c40b093556c274b5e40bc75feedb23b2c400aaea877274b5e40fb07ecc5ab3b2c40f962940c254b5e40e65ebb0f9b3b2c409bbf5312234b5e40edd632198e3b2c4065ac91b8224b5e40be21437d813b2c40b3ea18fc224b5e40f3e90ce7753b2c40d70b4ff9214b5e4043be9536663b2c4030404750214b5e40b7402729553b2c403026a204224b5e4020bcd122363b2c40d0b87020244b5e4024bac216163b2c4093dfa293254b5e402c0a606f073b2c4093dfa293254b5e403c4cfbe6fe3a2c40461449aa254b5e4029b8b30af63a2c40053f60d4244b5e40f7b0170ad83a2c405ecce039254b5e40440b1a44b53a2c40ac973a23254b5e406f319af0a63a2c4052f01472254b5e4040958911783a2c40),
(330, NULL, 'service', NULL, NULL, 'way/492131620', 0x0000000001020000000a000000e4d6a4db12525e40f08403c69f0d2c40856fab6a13525e4041d3122ba30d2c40d8b221a413525e407a354069a80d2c408b8ba37213525e40a78d8fbbad0d2c40d3b0cee712525e4088c4984fb10d2c403e0b9d3212525e402874a8f0b10d2c40c1d54b9d11525e40238f96b9af0d2c40f702b34211525e404faa2281ab0d2c401b66683c11525e40f82e4a75a60d2c40aa7c748f11525e409b66cb03a20d2c40),
(331, NULL, 'service', NULL, NULL, 'way/492131623', 0x0000000001020000000a000000c8ac832804525e40e109bdfe240e2c403fc6dcb504525e40c4c83780230e2c4060b829d409525e4000790a140c0e2c40ec74d65d0f525e40947fd2f5e90d2c40fdd98f1411525e4093420f6be00d2c40c7365fdb11525e40a9f92af9d80d2c407a99171612525e404e716605d00d2c4014a3f84212525e40f3e8a111c70d2c40567b7d5212525e408c7ed9e2bf0d2c403e0b9d3212525e402874a8f0b10d2c40),
(332, NULL, 'track', NULL, NULL, 'way/492131626', 0x000000000102000000020000009dcc898741525e407452a923910f2c400be654d746525e40863aac70cb0f2c40),
(333, NULL, 'residential', NULL, NULL, 'way/492364168', 0x0000000001020000000700000016dc0f7860525e4071636996ba122c402da2dc6c62525e40bbfc3d67c1122c408055e4c663525e407c952133bc122c4044824ead63525e4067994528b6122c40505e1a7563525e400ad1c6b6b1122c401bd82ac162525e4005ecb47faf122c40a57c523761525e409c89e942ac122c40),
(334, NULL, 'residential', NULL, NULL, 'way/492364170', 0x0000000001020000000b00000079c9ffe46f525e401288d7f50b122c40272724e362525e404c05cbc7a4112c40c1559e4058525e40649703988d112c4056eafe5657525e405e4a5d328e112c407a7e62ae56525e4015ee4bec90112c4046ea3d9553525e4068ffa8f2e2112c407ce9921653525e4058923cd7f7112c4016ed3bd054525e405b0fbadffc112c40c8abbd9962525e40273108ac1c122c40a9a0473165525e4073dfc5562b122c40c4622f6f69525e407289230f44122c40),
(335, NULL, 'residential', NULL, NULL, 'way/492364171', 0x000000000102000000020000009ba5098096525e40b15472a9a5102c40c1069f419e525e40f1ba7ec16e102c40),
(336, NULL, 'residential', NULL, NULL, 'way/492364172', 0x000000000102000000020000007e271c307e525e40031203136e102c40d7ff94858a525e40e1e58ea3de102c40),
(337, NULL, 'residential', NULL, NULL, 'way/492364173', 0x00000000010200000003000000bf6f32607f525e40ec600ecc1b112c40d7ff94858a525e40e1e58ea3de102c40efc0a50895525e40832ff1ec97102c40),
(338, NULL, 'residential', NULL, NULL, 'way/492364174', 0x00000000010200000004000000fd2fd7a285525e4061eea4cf58112c40bf6f32607f525e40ec600ecc1b112c40cbb84ec873525e40a6f7e868b0102c407a2ef8d96d525e402ff7c95180102c40),
(339, NULL, 'residential', NULL, NULL, 'way/492364175', 0x00000000010200000008000000fe7277e79a525e4085002a66ce102c409ba5098096525e40b15472a9a5102c40efc0a50895525e40832ff1ec97102c4006c94cb38a525e40afaa03c534102c403d2762b689525e40abc5f18d32102c40ea5fed8387525e4074c0649934102c407e271c307e525e40031203136e102c40cbb84ec873525e40a6f7e868b0102c40),
(340, NULL, 'residential', 'yes', NULL, 'way/492364176', 0x0000000001020000000300000024c09fd0a1525e40468a123ea5102c40659588a6a2525e40878494449b102c4077b8c260a3525e40d8254ffe93102c40),
(341, NULL, 'residential', NULL, NULL, 'way/492364178', 0x0000000001020000000900000024c09fd0a1525e40468a123ea5102c40fe7277e79a525e4085002a66ce102c40fd2fd7a285525e4061eea4cf58112c4079c9ffe46f525e401288d7f50b122c40c4622f6f69525e407289230f44122c40263b91bb63525e407dbfe2ba73122c40d989dc1d63525e405b26c3f17c122c40a57c523761525e409c89e942ac122c4016dc0f7860525e4071636996ba122c40),
(342, NULL, 'residential', 'yes', NULL, 'way/492364179', 0x00000000010200000003000000e811482ea4525e409923d0059a102c406b97db62a3525e405a492bbea1102c4024c09fd0a1525e40468a123ea5102c40),
(343, NULL, 'service', 'yes', NULL, 'way/496549359', 0x0000000001020000000200000030f1ec9774425e40ce2dbeb21c6a2d4012de793d73425e40d95f764f1e6a2d40),
(344, NULL, 'service', 'yes', NULL, 'way/496549361', 0x0000000001020000000200000012de793d73425e40d95f764f1e6a2d405b1d4afe71425e40a25ae95a206a2d40),
(345, NULL, 'service', 'yes', NULL, 'way/496549365', 0x00000000010200000003000000aabb0dc578425e408977256eba6a2d400435215278425e4057d526a9a76a2d40639c1ac377425e4081762c5b906a2d40),
(346, NULL, 'service', 'yes', NULL, 'way/496549366', 0x00000000010200000003000000639c1ac377425e4081762c5b906a2d40b139628877425e404fc939b1876a2d40c31a1d4677425e4031bb82c87d6a2d40),
(347, NULL, 'service', 'yes', NULL, 'way/496549370', 0x0000000001020000000400000006ae3c925c425e4067576b72426a2d40531ad6f95c425e4013e6875b4f6a2d402cf2eb8758425e40158bdf14566a2d40caff3fa951425e40405bbd79606a2d40),
(348, NULL, 'unclassified', NULL, NULL, 'way/517121603', 0x0000000001020000000f0000003a07cf84264b5e40e82e89b3223a2c407023658b244b5e4002fd74f2d8392c40b9f2a32b224b5e40b028db7690392c40362e2d34214b5e40845cf3f45b392c40cbbc55d7214b5e40ca91297a3b392c40a6c3f98a244b5e40f1aabd3e29392c4010b633a7264b5e401f4ebbf31f392c407f4b00fe294b5e40d82e6d382c392c402b2dc83b2c4b5e408fd25bf22e392c4089b663ea2e4b5e4031a53f451f392c4082f057b7304b5e40146faeab13392c4069a5b50e334b5e40729fc14b15392c40267f411c354b5e4061b0d12813392c403d450e11374b5e40381db74e12392c40307777ae394b5e40cb129d6516392c40),
(349, NULL, 'service', NULL, NULL, 'way/517121604', 0x0000000001020000000400000069a5b50e334b5e40729fc14b15392c400e3ad7e6354b5e4009f945ae40392c40d2d336b4374b5e404d8237a451392c408f064bd03a4b5e40f5392d2e44392c40),
(350, NULL, 'service', NULL, NULL, 'way/517121605', 0x00000000010200000002000000307777ae394b5e40cb129d6516392c408f064bd03a4b5e40f5392d2e44392c40),
(351, NULL, 'service', NULL, NULL, 'way/517121606', 0x00000000010200000004000000d2d336b4374b5e404d8237a451392c401336f22f384b5e401fdf39ef5a392c4036c41d14394b5e40c56867e267392c40956d9681394b5e40fd82ddb06d392c40),
(352, NULL, 'unclassified', NULL, NULL, 'way/517121607', 0x00000000010200000004000000307777ae394b5e40cb129d6516392c40bfa48c133a4b5e40d60a896a00392c4059219b9a3a4b5e4004013274ec382c40fe3ff3de3d4b5e40841d1032da382c40),
(353, NULL, 'service', NULL, NULL, 'way/537057614', 0x0000000001020000000b0000000dd3ad8de7515e402d12c946d6102c40504dee1cef515e40f849ffdce1102c40772d211ff4515e40cbe6bba5e6102c40946ea69df5515e4026c22beee4102c40e26def6401525e40d1f1875572102c40a59421d802525e409122d7f26f102c40c098881208525e407fcb52a170102c409c77521509525e401a4e999b6f102c4070e998f30c525e400e32c9c859102c4025eb707415525e4027d5e3631c102c4000b3316516525e401f2b9db415102c40),
(354, NULL, 'footway', NULL, NULL, 'way/537057632', 0x00000000010200000002000000cd80690792525e40a01fa1c101102c4055a3570394525e40fd8282f7fa0f2c40),
(355, NULL, 'path', NULL, NULL, 'way/549204659', 0x00000000010200000009000000f1683e42284b5e40400812256b3a2c40d3f0d2f2284b5e403a56ce83603a2c40fd6ce4ba294b5e403aff1b203d3a2c40843012352c4b5e40a2ad94af153a2c405eec623f304b5e40b3d5404ef3392c406224c511354b5e40f7e7a221e3392c40ac30c73c3c4b5e405e961bb1bb392c408799c7ab3d4b5e40f9235690b0392c40b631d17b3e4b5e4002f96de3aa392c40),
(356, 'Kindness Avenue', 'residential', NULL, NULL, 'way/549654400', 0x00000000010200000026000000e4e8e04f43415e4023a12de752682d405517f03243415e40af496d9857682d409dc9ed4d42415e4096b43dd57c682d40449b2d6a41415e40483a5edca1682d40264003a040415e40ec055559ca682d400fd0228040415e40b308c556d0682d40333674b33f415e407a6ddb9cef682d405757aab03e415e4002a8983913692d4069520aba3d415e4035a440553b692d40d0decfdf3a415e40c4c02962c7692d4089d6e5ef39415e405ad2f654f3692d400124891439415e407b4f406e1a6a2d40fcc8ad4937415e40b4d25a87596a2d40c06be1c336415e405e914e136c6a2d40a9fb00a436415e40fb703557726a2d4008043a9336415e406323b5f5786a2d402662009736415e40a7b79ad07f6a2d40021654af36415e4079ecc26a876a2d403d00f3da36415e40c942cfc18e6a2d40fc9a9b2537415e4053f30b65976a2d4049d9226937415e405ce509849d6a2d40c0c469d237415e404ceb257ca56a2d406c674e4d38415e406b894b44ae6a2d405acbaec538415e4091048651b56a2d40a11b502539415e40ac4d08c2ba6a2d404e79196a39415e4010abe408be6a2d4089d6e5ef39415e40f50eb743c36a2d407d6d47823a415e405e995c31c86a2d408ed59c723b415e404972af82ce6a2d406a3e9de13c415e4021640fa3d66a2d40528605523d415e40d807fe5cd96a2d403ace6dc23d415e407d5468c5dc6a2d407beb0d083e415e40f87d4974e06a2d407b30293e3e415e40fc427eece46a2d4093b712703e415e408783296fec6a2d406f264b523e415e40a8363811fd6a2d40528605523d415e40608f8994666b2d405213d8f73c415e409a2e7a5d756b2d40),
(357, 'Angela Avenue', 'residential', NULL, NULL, 'way/549659581', 0x00000000010200000007000000262da6e37b415e40191c25afce692d4068e6c93585415e40092241a7d6692d40e5bc5a4986415e405bb8077cd9692d400e0b5aed86415e409462ec29de692d400759bb9289415e40d8309e9cfc692d40a71c380c8b415e409dc88278136a2d40e2a47a7c8c415e405aab2cc02d6a2d40),
(358, 'Angela Avenue', 'residential', NULL, NULL, 'way/549659604', 0x00000000010200000003000000262da6e37b415e40191c25afce692d4034e7cf6d78415e40a31f0da7cc692d40e7f6370d76415e404bf4e8fcca692d40),
(359, 'Courage Street', 'residential', NULL, NULL, 'way/549663756', 0x0000000001020000000a00000086dbebee4b415e407889a02067682d401a958a7c4d415e405197d6f03e682d4037667eda4d415e40f5a67dce38682d40971b0c7558415e400f5c8a5011682d404f0a4ed859415e406f84a0fe0e682d40cc3f9f6d5a415e40d99eb4cb12682d400d7448c55a415e403c9bfae538682d40c6adddd15a415e40e22428d945682d409c1727be5a415e4049b7cab84e682d40c0f0a54b5a415e40a50cc11660682d40),
(360, 'Amity Street Extension', 'residential', NULL, NULL, 'way/549812770', 0x00000000010200000005000000ea7ea9fa70415e4046a5c7a5e0672d40a49300906e415e4060b1868bdc672d407a8a1c226e415e40729879bcda672d402159c0046e415e40f1b16087d6672d4086048c2e6f415e40957549e6a2672d40),
(361, 'Chanel Street', 'residential', NULL, NULL, 'way/550853110', 0x00000000010200000005000000e715f483df425e40b90db44cd0682d405e770481df425e40d4a9e111cb682d4011397d3ddf425e40e68ccd339b682d40291f27f1de425e4020b41ebe4c682d40d520ccedde425e40453a4db049682d40),
(362, 'Armani Street', 'residential', NULL, NULL, 'way/550853111', 0x0000000001020000000500000026016a6ad9425e40d7265f1ad0682d40a9836165d9425e40038aa251cb682d403efe1c30d9425e40c82b6bf69b682d408b5649bfd8425e4064b895b954682d4073fd71b1d8425e4062eb634f4c682d40),
(363, 'Burberry Street', 'residential', NULL, NULL, 'way/550853113', 0x00000000010200000004000000e7fba9f1d2425e40a6c7009a52682d404d37e4fad2425e40fec753a060682d40ff6b8a11d3425e40d04543c6a3682d4029d42e01d3425e402420cb27d0682d40),
(364, 'DKNY Street', 'residential', NULL, NULL, 'way/550853116', 0x000000000102000000030000005e995c31c8425e4077d267aca2682d4028dc86acc9425e40b9c1f5cda2682d40ff6b8a11d3425e40d04543c6a3682d40),
(365, 'Givenchy Street', 'residential', NULL, NULL, 'way/550853119', 0x000000000102000000080000005e807d74ea425e406b7ccb4175682d40edf2ad0feb425e409aa443f174682d40315c1d00f1425e40b0a316ef6c682d40d86c40dff1425e403a1790076c682d4011e91269f6425e40016dab5967682d40b5edc561fa425e406e77c54263682d400e5e0542fc425e403f6f2a5261682d40a4e4d53906435e40ebc37aa356682d40),
(366, 'Mulberry Street', 'residential', NULL, NULL, 'way/550853122', 0x0000000001020000000a0000006a3f08b7eb425e40afcdc64acc672d407016e588eb425e407cfdffeed3672d4029e0e874ea425e4023f3c81f0c682d40b250c653ea425e406db477a114682d408ed60748ea425e406e81a90b1d682d40e1d4624bea425e40b7b2e9ad26682d401775f74aea425e4000868a1645682d405e807d74ea425e406b7ccb4175682d400b992b83ea425e4008fb1b599e682d4011b5238bea425e409bf00170a2682d40),
(367, 'L. Vuitton Street', 'residential', NULL, NULL, 'way/550853123', 0x0000000001020000000d0000004320f2f1e4425e40d52a55fda5682d40cc8d3397e5425e402829b000a6682d40bf60dcb2e8425e4040852348a5682d40dc0022b3e9425e40f9d85da0a4682d4011b5238bea425e409bf00170a2682d40d3421372ef425e4044108c2892682d40ac51b417f6425e40b515a0127c682d408c852172fa425e409e4c929d6d682d4056b4de14fb425e40345a58816b682d40c7b13f9afb425e40d06c0d5b69682d40b5e78deefb425e408a986d0267682d4091c9f32afc425e409d0fcf1264682d400e5e0542fc425e403f6f2a5261682d40),
(368, 'Versace Street', 'residential', NULL, NULL, 'way/550853124', 0x0000000001020000000a00000070044e5bc8425e40a55478865f682d40e7fba9f1d2425e40a6c7009a52682d40b72f568ad3425e400013020352682d4073fd71b1d8425e4062eb634f4c682d40b55f2d2dd9425e40b02c87cc4b682d408ad7ab7edb425e40ab47759549682d40188c5b16dd425e40049376fe48682d40d520ccedde425e40453a4db049682d40ff40b96ddf425e4051fc732c4a682d403875d487e4425e40017b96314f682d40),
(369, 'Hermes Street', 'residential', NULL, NULL, 'way/550853126', 0x000000000102000000060000004a568f45e4425e403df19c2d20682d405f7d3cf4dd425e4017be199018682d4042c6ede1dc425e4006f7031e18682d4001c3f2e7db425e400bb43ba418682d40c227e7d5ca425e402a6f47382d682d40c2418c21ca425e40540262122e682d40),
(370, 'S. Francisco Street', 'tertiary', NULL, NULL, 'way/550853127', 0x0000000001020000000e000000742502d5bf425e400b91781e81682d40eee30dd5b9425e4016c330bb82682d40417dcb9cae425e404a404cc285682d407957e2a6ab425e40850a0e2f88682d400f48c2be9d425e4024d40ca9a2682d40b602f9c89c425e405f2e3df5a3682d4069b004ad9b425e40d6027b4ca4682d4043dc419193425e40379325299f682d400ee3248392425e409c58969e9f682d4033045b8091425e409533cae9a1682d40f76173c490425e40b19c2919a5682d40e8644e3c8c425e40c1edbf84c0682d40902d701e73425e4091161d7f58692d40ae8ed25b72425e4022cc481861692d40),
(371, 'Quartz Street', 'residential', NULL, NULL, 'way/550853128', 0x000000000102000000050000006da8bd2dfd425e4073e83e4a36682d4036d1425dff425e40081edfde35682d401db4b2d801435e408857a3682f682d401c9a0d8d02435e40af45668929682d40bd0402f802435e40c52753bb15682d40),
(372, 'Pearl Street', 'residential', NULL, NULL, 'way/550853136', 0x00000000010200000004000000d7a02fbdfd425e40f04dd36707682d406fd4af1905435e4042c7b370fe672d40aef94c5109435e40a5773b0cf7672d4011f868160d435e40ebc5504eb4672d40),
(373, 'Diamond Avenue', 'residential', NULL, NULL, 'way/550853137', 0x0000000001020000000f0000005e4a5d320e435e40511b30a3b3672d40099f52ca10435e4077de2120ba672d40d36e4feb11435e4076768df1bc672d406b949ae216435e4056ca7c51cc672d40c40776fc17435e40fb16e7b9cf672d406a15fda119435e406b0e10ccd1672d40cee8a27c1c435e400c4e8e4cd1672d4057b5a4a31c435e40c5591135d1672d40c5ba021b21435e4073c34a60ce672d408a71a36d21435e40606cc60ecf672d400043458b22435e4053420b64d1672d403c44edc822435e4065c16966d2672d40abc54c4725435e4044adc497e4672d4082a2c38d25435e40f66ba11ae5672d40757ba41c27435e400833b78ce5672d40),
(374, 'Sapphire Street', 'residential', NULL, NULL, 'way/550853138', 0x000000000102000000040000007ce184f8f6425e405677d1fcd6672d40dc6223b5f5425e40a1ecd22b0a682d40b2cc6ca1f5425e40794ec46c13682d40e2500999f5425e40768d96033d682d40),
(375, NULL, 'service', NULL, NULL, 'way/553751409', 0x00000000010200000006000000370f71bdb7415e40248e869d73692d407e79b768b7415e40fc1a498270692d40fcb1a437b7415e402231e6536c692d409762fd55b6415e403849980e42692d40dfb8d628b5415e4006989e550b692d40f15712eab3415e408cb564faca682d40),
(376, NULL, 'service', NULL, NULL, 'way/553751410', 0x00000000010200000007000000370f71bdb7415e40248e869d73692d407e8d2441b8415e40a6dc330175692d404ec1d0d9b8415e4000e07dfa74692d402aa913d0c4415e4014121f8e64692d4095319985d1415e40c4c6061c53692d40fa241c1fd2415e40e8740fbf51692d40fa974979d2415e40d7851f9c4f692d40),
(377, NULL, 'service', NULL, NULL, 'way/553751411', 0x00000000010200000005000000ee1dda6cd1415e40671b6e765a692d405930f147d1415e40c9586dfe5f692d40a1c84917d1415e409dad725765692d40892a57d3d0415e402351c3126a692d40b43fab27ce415e40e6e5b0fb8e692d40),
(378, NULL, 'service', NULL, NULL, 'way/553751413', 0x000000000102000000030000005c77f35407425e40fd378a07ef662d40f911bf620d425e40f6a22c32f0662d4096d7005b14425e407ef6c88bf1662d40),
(379, NULL, 'service', 'yes', NULL, 'way/553751414', 0x0000000001020000001c00000073ecea9ff1415e4086f2f400cc672d40c6014fb5f1415e40e73ae86dc7672d402566acecf1415e401f605221c3672d40669a5544f2415e4009449957bf672d4078616bb6f2415e40dbcb6c46bc672d40487e0e3df3415e40d0e16b19ba672d4065941dd1f3415e4084786eebb8672d4036c8c969f4415e403c84f1d3b8672d40b2fd1afff4415e40a7069acfb9672d400bb9ad88f5415e407606fcd0bb672d40053ef5fef5415e4010913fbdbe672d40c3efa65bf6415e408bba206cc2672d40fff04e99f6415e405f9f94a4c6672d40644392b4f6415e40575aeb30cb672d40c967c3abf6415e40ef0c09cecf672d408e7d2480f6415e40f9d62c3cd4672d4011a4f732f6415e40f1d93a38d8672d409ab8b0c9f5415e40f52ede8fdb672d40a6385849f5415e4077ed1c14de672d40a7800fb9f4415e403a2b5899df672d40ade4be30f4415e4046ed7e15e0672d401e8997a7f3415e402e217aaddf672d406ccaba24f3415e40edc15a6bde672d40254c07a1f2415e40a7edba12dc672d40fb422333f2415e40e487a5dcd8672d4001ecede0f1415e40347914f8d4672d40ea6404aff1415e40cba6b79ad0672d4073ecea9ff1415e4086f2f400cc672d40),
(380, NULL, 'service', NULL, NULL, 'way/553751415', 0x0000000001020000000a000000bb8a7be2ef415e40838aaa5fe9682d4026ce401bef415e40475854c4e9682d40507e9c7aee415e400cb66c08e9682d40e9fcca39e7415e40a4e6069ed6682d409192c3cce3415e4078ae940acf682d409919ec3ce0415e4029e8f692c6682d40674c1cd4d9415e40748fb63bb5682d40b1868bdcd3415e405e9ece15a5682d401dcdec4ed2415e40ad4786c1a1682d40a19a37f3d0415e405a01744ea2682d40),
(381, NULL, 'footway', NULL, NULL, 'way/553751416', 0x0000000001020000000200000065fcfb8c8b415e403af4cc81d4682d40fda8e1b691415e40b8fbc165ba682d40),
(382, NULL, 'footway', NULL, NULL, 'way/553751417', 0x00000000010200000002000000dd3532d989415e409b59a6badb682d4065fcfb8c8b415e403af4cc81d4682d40),
(383, NULL, 'service', NULL, NULL, 'way/553751420', 0x00000000010200000003000000a19a37f3d0415e405a01744ea2682d40f15712eab3415e408cb564faca682d40d57b8560b0415e40b308c556d0682d40),
(384, NULL, 'service', NULL, NULL, 'way/553751422', 0x00000000010200000004000000f15712eab3415e408cb564faca682d4039ab4f83b3415e402074756ca9682d40aa1e7a9cb3415e40fb88a93ea1682d400cb89d6cb9415e40e679cb3049682d40),
(385, NULL, 'footway', NULL, NULL, 'way/553751423', 0x00000000010200000002000000193d128a88415e407935e5af35682d402eeef5a482415e40f7d84c744c682d40),
(386, NULL, 'footway', NULL, NULL, 'way/553751424', 0x00000000010200000002000000848bcba77d415e4096f4e62620682d4041310d1e81415e4031e7be4120682d40),
(387, NULL, 'residential', NULL, NULL, 'way/553762544', 0x000000000102000000040000003723394f2b425e408b15dade13682d4079b6a2282b425e40d63329aa23682d40670696c82a425e40aaffbd254a682d40ba3203f02a425e40b55950734d682d40),
(388, NULL, 'residential', NULL, NULL, 'way/553762545', 0x0000000001020000000400000079b6a2282b425e40d63329aa23682d40b9fb1c1f2d425e407c58b96125682d40f95404ee2f425e40b01d8cd827682d408c02339534425e40840200112c682d40),
(389, NULL, 'residential', NULL, NULL, 'way/553762563', 0x00000000010200000002000000532a3cc32f425e404f4c288e4d682d40f95404ee2f425e40b01d8cd827682d40),
(390, NULL, 'residential', NULL, NULL, 'way/553762585', 0x000000000102000000030000000f9c33a234425e403ecdc98b4c682d408c02339534425e40840200112c682d403804d89134425e40f9090cfe23682d40),
(391, NULL, 'residential', NULL, NULL, 'way/553762605', 0x00000000010200000005000000ba3203f02a425e40b55950734d682d40ea40d6532b425e4007c83c974e682d40532a3cc32f425e404f4c288e4d682d400f9c33a234425e403ecdc98b4c682d40eb63f49235425e405ce674594c682d40),
(392, NULL, 'residential', NULL, NULL, 'way/553767023', 0x000000000102000000020000009e013ff46e415e40a977a7f1c1692d40cdcaf6216f415e408555061f94692d40),
(393, NULL, 'residential', NULL, NULL, 'way/553767024', 0x000000000102000000020000004c6e14596b415e40fbe18c0695692d40d5def1376b415e40db27918ebc692d40),
(394, NULL, 'residential', NULL, NULL, 'way/553767025', 0x00000000010200000003000000bd6a0a09bd415e40df4ec7084d6b2d40e6875b4fbe415e40d28f8653e66a2d4015db49e9be415e4059935d1f8c6a2d40),
(395, 'Leo Street', 'service', NULL, NULL, 'way/553767028', 0x000000000102000000040000008299a5530d425e4004691030046a2d407cd9d1930d425e40e70aa5e5f6692d407602f5c10d425e404f8358ece5692d40a6b4a3dd0d425e402950d54ede692d40),
(396, 'Gemini Street', 'residential', NULL, NULL, 'way/553767029', 0x0000000001020000000500000068fd778e12425e40d4a12eade1692d40c778ded712425e4046d9113ddf692d40cdc2e80313425e402a28fb9ddc692d4079c1f1c613425e4088d68a36c7692d40305173a815425e403fc91d3691692d40),
(397, 'Benevolence Street', 'residential', NULL, NULL, 'way/553774750', 0x0000000001020000000900000044577d0970415e406e4cf49e6f682d40a9a9c02470415e40524832ab77682d40a9a9c02470415e4048e3ab787e682d40bbb88d0670415e402cdfe98486682d40cd57c9c76e415e40b2ae1b00bb682d40fdc7f8e66d415e40349c3237df682d4098309a956d415e404ccdd4daea682d40f2d7bf466d415e40484d60dff3682d403f30ecd56c415e40eff66a91fe682d40),
(398, 'Courage Street', 'residential', NULL, NULL, 'way/553774757', 0x00000000010200000003000000c0f0a54b5a415e40a50cc11660682d40739b15f659415e4030bdfdb968682d40c180142b59415e40f454e2957f682d40),
(399, 'Joy Street', 'residential', NULL, NULL, 'way/553774763', 0x00000000010200000011000000e07fd01f3f415e40f06f2b18f0692d4033c346593f415e403744cb70f2692d40b09c73a63f415e40d1a634acf3692d40c18eff0241415e4047a34cb4f5692d4067e43d1842415e40f3cccb61f7692d4019445a1943415e40da9832cbf9692d403c00982144415e4008115fdcfc692d4024a188a045415e404630c4a0026a2d4064b8f07247415e40fb4b416d0a6a2d400b11cbc147415e4006c6b0790b6a2d40ab7bbf2c48415e40b8848dfc0b6a2d40348ddc8948415e40f4b6e3970b6a2d40c9bfe0e448415e4089343b9c0a6a2d402e40362449415e4001e19e42096a2d40e289c51451415e404027ce9bd4692d40f40bc05051415e40b25eb12bd2692d40c49e2c6b51415e40fb720b02d0692d40),
(400, 'San Jose Street', 'residential', NULL, NULL, 'way/553774797', 0x000000000102000000040000006eade5843f415e40144438c1926a2d40fdf49f353f415e40076d286b8a6a2d400384c5973f415e40d4d51d8b6d6a2d401a7b40ea40415e40dc5e775f3a6a2d40),
(401, NULL, 'service', NULL, NULL, 'way/553779666', 0x000000000102000000020000003f1efaeed6415e406b065d67e8682d40b2d47abfd1415e40b9e2e2a8dc682d40),
(402, NULL, 'service', NULL, NULL, 'way/553793559', 0x000000000102000000020000000812256b9e415e402a93759373692d401812e62ca2415e40c8725cd779692d40),
(403, NULL, 'service', NULL, NULL, 'way/553793568', 0x000000000102000000030000001812e62ca2415e40c8725cd779692d406bc5ed86a3415e400b0e2f8848692d40d2544fe69f415e404ae8d3cf40692d40),
(404, NULL, 'service', NULL, NULL, 'way/553793569', 0x000000000102000000030000009d30bced9d415e40e560360186692d400812256b9e415e402a93759373692d40d2544fe69f415e404ae8d3cf40692d40),
(405, NULL, 'footway', NULL, NULL, 'way/553793570', 0x00000000010200000002000000ace0b72146415e40f59b2e30d06a2d40f4eed98445415e402ef36789df6a2d40),
(406, NULL, 'service', NULL, NULL, 'way/553793573', 0x00000000010200000003000000311bae1f2c415e4016e2ec31ec6b2d40d81d9c992a415e4034434f6feb6b2d40af004b5329415e401edfde35e86b2d40),
(407, 'Davies Lane', 'residential', NULL, NULL, 'way/553793574', 0x00000000010200000005000000c3e5c2923c415e409cfbabc77d6b2d409aaecc003c415e4021c8e64fc06b2d406ba395d63a415e406e9e8fd7286c2d4095b2b1b739415e408df8043f606c2d403c9bfae538415e400369b576916c2d40),
(408, 'Justice Street', 'residential', NULL, NULL, 'way/553793575', 0x00000000010200000008000000f201261532415e40082a99524d6b2d40528605523d415e40608f8994666b2d403172bb3c42415e40901c9f7f716b2d400e3d186742415e40c6014fb5716b2d401fa8099142415e407808e3a7716b2d405b92a8bc42415e4043233372716b2d40c600e4df42415e40cc4ef51a716b2d40192d510743415e40eaaf5758706b2d40),
(409, NULL, 'residential', NULL, NULL, 'way/553793576', 0x00000000010200000002000000e3f093b42c415e40488ecfbfb86b2d401b7222b028415e407d9b59a6ba6b2d40),
(410, NULL, 'residential', NULL, NULL, 'way/553793577', 0x000000000102000000060000001b7222b028415e407d9b59a6ba6b2d40bcdfb25428415e40936a44d5546b2d40aa5a1cdf28415e40c9c27c1e486b2d404f7974232c415e40b1283630036b2d40c05fcc962c415e4064bf3802026b2d40f9de3a5a30415e408e2a792b016b2d40),
(411, 'Justice Street', 'residential', NULL, NULL, 'way/553793579', 0x0000000001020000000b0000006f264b523e415e40a8363811fd6a2d40224a20ca3c415e4077a62b33006b2d4097d52ab036415e40c8bb7e1c286b2d402e90a0f831415e4059839c9c466b2d4052dc4ce031415e40ff379b33476b2d409386bfcb31415e409f9ff364486b2d407b2de8bd31415e40bd283053496b2d407b2de8bd31415e40159c0b6d4a6b2d40d5473bc931415e40c20d428a4b6b2d408d98d9e731415e40268bfb8f4c6b2d40f201261532415e40082a99524d6b2d40),
(412, NULL, 'service', NULL, NULL, 'way/553793580', 0x000000000102000000020000009dec0b8d4c415e404f43af9a426a2d40633953324a415e406405bf0d316a2d40),
(413, 'Justice Street', 'residential', NULL, NULL, 'way/553793582', 0x00000000010200000017000000192d510743415e40eaaf5758706b2d40725ead2443415e40c7212c746f6b2d403dd5213743415e409e8e119a6e6b2d4096ef744243415e40391158946d6b2d40decce84743415e40ce8eaf986c6b2d404339d1ae42415e40f6ebf3bd2b6b2d404339d1ae42415e40a3c5be092a6b2d405b92a8bc42415e40d37da598286b2d4085285fd042415e40aaea8abe276b2d407f3a79ec42415e40f82bae3b276b2d406121ce1e43415e403a63f3cc266b2d40ee2e06c545415e408ec9e2fe236b2d40d0155bf745415e406bf3ffaa236b2d4047bc862a46415e407d4a84fc226b2d405927785446415e4024d7a8e2216b2d4041fcb26a46415e404985b185206b2d40dcd7817346415e40f65e7cd11e6b2d409a16067646415e40a9f57ea31d6b2d40a191beff45415e40b560f3bbfa6a2d4095fda9a745415e40e626c522e16a2d40e2df0ca345415e404c7ca477e06a2d40a107889345415e4058ce39d3df6a2d40f4eed98445415e402ef36789df6a2d40),
(414, 'Joy Street', 'residential', NULL, NULL, 'way/553793716', 0x00000000010200000008000000097888354b415e401768d201a4692d4017d3f13d48415e4010a8a388b1692d40e1bf2fe447415e4075255d8eb2692d401ddb7c6d47415e4086a4bb90b3692d40dc78c1f146415e40c28e5abcb3692d407197587446415e405dc9e946b3692d4012c0cde245415e400a1346b3b2692d409e73017940415e4043588d25ac692d40),
(415, 'West Fresno Street', 'residential', NULL, NULL, 'way/553793735', 0x00000000010200000003000000be65f3dd52415e403436cf6cb2692d40b13b383355415e403c45b357c4692d40d5dbb0b75e415e408772fd16f8692d40),
(416, NULL, 'service', NULL, NULL, 'way/553793739', 0x0000000001020000000300000066ed009967415e40a82be97294692d404c6e14596b415e40fbe18c0695692d40cdcaf6216f415e408555061f94692d40),
(417, NULL, 'service', NULL, NULL, 'way/553793740', 0x000000000102000000050000000759bb9289415e40d8309e9cfc692d4048bb760e8a415e40e6eac726f9692d40d7eb27ad89415e40487b7203f4692d40b8c60cf98c415e401a76ce05e4692d404048bb768e415e400c91d3d7f3692d40),
(418, 'Acme Road', 'residential', NULL, NULL, 'way/553793742', 0x00000000010200000017000000ca6fd1c9d2415e40f303577902692d40f378b537d3415e401b947a6011692d40828fc18ad3415e40988a8d791d692d4034620be6d4415e403c4b901150692d40bcfd5eafd5415e408d8bb49e6b692d40f8713447d6415e400eff44c07c692d40f2834e63d6415e40f3aace6a81692d404b9ea16ed6415e4039a7487485692d40ec67565bd6415e40a736dd578a692d40b066ae1dd6415e4057b5ff5c8f692d40e08e26cdd5415e4002bfa14b93692d40c336983cd4415e40a728f27fa2692d408e51e806d4415e403f4ba13da8692d405eb642fdd3415e40d76d50fbad692d40b7fea72cd4415e40c8db0022b3692d40b1694a57d5415e40b8b64b76c7692d408158dbb9d5415e40cd8a4dd0cb692d40047c1233d6415e409cb28982cf692d402d6eed8ed6415e40c99a47b4d3692d40278007abd6415e40df6e490ed8692d40b007ee9bd6415e40a1b48185dd692d40c2ffb16bd6415e404529c69ee2692d40bf9f75e8cf415e40b5c766a2636a2d40);
INSERT INTO `streets` (`Id`, `Name`, `Highway`, `Oneway`, `OldName`, `StreetId`, `Geometry`) VALUES
(419, NULL, 'service', NULL, NULL, 'way/553793753', 0x0000000001020000000200000086b07504cb415e40f9742b3a486a2d40e8f28bb7ba415e40ce5c96653e6a2d40),
(420, NULL, 'service', NULL, NULL, 'way/553793754', 0x0000000001020000000200000086b07504cb415e40f9742b3a486a2d4009d4ac7dcb415e408eee7b2f196a2d40),
(421, 'Bally Street', 'residential', NULL, NULL, 'way/557184132', 0x00000000010200000007000000315c1d00f1425e40b0a316ef6c682d40aeab13e1f0425e40eac083b064682d402cfea5fbef425e4069290fc127682d40b59c95feef425e40ce1951da1b682d40f06f2b18f0425e40c8670d3911682d401418fc47f0425e4056eb692c06682d40f640d076f1425e40d5004ae8d3672d40),
(422, 'Tomford Street', 'residential', NULL, NULL, 'way/557184133', 0x0000000001020000000a000000f640d076f1425e40d5004ae8d3672d406a3f08b7eb425e40afcdc64acc672d402532bd0ee6425e40e39d8da6c4672d40d2c3d0eae4425e40e475b3f5c2672d409fd9bffcdf425e40bdb2c178bc672d40a0b1e54bde425e40e260ca1bbb672d4018169282dd425e40a0713cfaba672d4018192ebcdc425e401d4b6947bb672d4078c59d1ccf425e40ab306c83c9672d407f880d16ce425e405da79196ca672d40),
(423, NULL, 'residential', NULL, NULL, 'way/557184135', 0x00000000010200000004000000f33e8ee6c8425e4093af5f0bd5682d4039c59915c0425e40c8940f41d5682d408662e1dabf425e40fe310807d6682d4015d8adafbf425e40df88ee59d7682d40),
(424, NULL, 'residential', NULL, NULL, 'way/557184137', 0x000000000102000000030000003dd52137c3425e4036a33039ff682d40825bd2acc7425e40f5b3a217ff682d40b76e9406c8425e40cb20883dfe682d40),
(425, 'Bvlgari Street', 'residential', NULL, NULL, 'way/557184138', 0x00000000010200000008000000982fd406cc425e40a2cfec5ffe672d40cdfadef0cc425e404f61003cfd672d4072924149dc425e4059f15712ea672d4071bdb733dd425e40b8414871e9672d401d18e53ede425e40a77a32ffe8672d40176c7e57df425e40fa30d692e9672d406de75663e4425e40afdcc13ef0672d4038e801e2e4425e40f68887e6f0672d40),
(426, 'Gucci Street', 'residential', NULL, NULL, 'way/557184139', 0x0000000001020000000e0000002532bd0ee6425e40e39d8da6c4672d400173e3cce5425e4061b47d7ece672d4038e801e2e4425e40f68887e6f0672d406150a6d1e4425e4089c6246df4672d404451a04fe4425e40687cba151d682d404a568f45e4425e403df19c2d20682d409d54ea48e4425e404146408523682d403875d487e4425e40017b96314f682d40d350a390e4425e406fea4d5656682d40673e8cb5e4425e408fe21c7574682d40dee4b7e8e4425e4084b46be7a0682d404320f2f1e4425e40d52a55fda5682d40fc9ea234e5425e406e5402bdcb682d40977a713de5425e4048f6ad7bd0682d40),
(427, 'Saint Thomas Street', 'residential', NULL, NULL, 'way/557184144', 0x00000000010200000006000000e16a532b02435e40db49e93ea5672d4059a1ed3d01435e401b199aa1a7672d40f4684f6e00435e4003756feaa8672d40188a856bff425e40e5130dada9672d403678ba4efe425e40385a1f20a9672d40cb564dc6e7425e4033f389e18f672d40),
(428, 'Yakal Street', 'residential', NULL, NULL, 'way/569378517', 0x00000000010200000002000000f3716da898425e40cf7a42c06b692d409ed733df9c425e40d322916c64692d40),
(429, NULL, 'residential', NULL, NULL, 'way/569378518', 0x0000000001020000000500000096a0754389425e40482a9d595c692d4055c8f03389425e40ab3fc23060692d4030d5cc5a8a425e401d3ee94482692d407db1f7e28b425e40f0e9a001ab692d407cabbf6f8d425e40f37519fed3692d40),
(430, 'Tanguile Street', 'residential', NULL, NULL, 'way/569378519', 0x00000000010200000005000000e6eb8db59a425e4015281884a8692d409f28bffb99425e408c7ad2d391692d40f3716da898425e40cf7a42c06b692d40fa7c941197425e4078a8b75043692d40cb85cabf96425e403fb61b333f692d40),
(431, NULL, 'residential', NULL, NULL, 'way/569378520', 0x00000000010200000006000000d4f60a66a7425e40d600a5a146692d40633ec516a7425e4085fa4cac42692d400a6c297ba6425e4039b12c3d3f692d40be4ae3bca4425e407e48090b38692d40b8489000a4425e40382cb24236692d40a7f74322a3425e4067542af235692d40),
(432, 'Ester Street', 'residential', NULL, NULL, 'way/569379962', 0x000000000102000000040000008d953daeb2425e40c3baf1eec8682d40be840a0eaf425e40ba23ad4214692d40ca60d6d5ae425e40606523c621692d4095c041d6ae425e402b2dc83b2c692d40),
(433, 'Sapphire Street', 'residential', NULL, NULL, 'way/569391820', 0x0000000001020000000200000000694991c6425e40a34918bc9e662d40c5f70f33c5425e4001fcae63b7662d40),
(434, NULL, 'service', NULL, NULL, 'way/569391821', 0x0000000001020000000900000066be839fb8425e40e3f093b42c692d4007b64ab0b8425e40199c775215692d40072c1444b8425e405eeb9cb00e692d4090ca0347b8425e4042823d810b692d40ad0e25ffb8425e40951bfb4800692d404e4b0746b9425e40e91c4d3ff2682d40a11b5025b9425e408192a751ed682d4049f02b7bb7425e4044dbd6bbe4682d4080c7a64bb5425e40520c906802692d40),
(435, 'Topaz Street', 'residential', NULL, NULL, 'way/569413686', 0x00000000010200000006000000421fd1a9d0425e4005d1a45e01662d40c138b874cc425e40d459773de2652d405704ff5bc9425e40671591bcce652d4034a4e59bc8425e40157fcae7cb652d402fa292dfc7425e404b8457dcc9652d40ff209221c7425e40bde3141dc9652d40),
(436, NULL, 'service', NULL, NULL, 'way/569413687', 0x00000000010200000005000000f69be4a2b5425e40610b8b9b64652d4097207e59b5425e404c01c4b876652d409d3c7661b5425e404803d3c496652d40689ce161b5425e4093043cc49a652d40f60e12fdb5425e40a0ea460ec7652d40),
(437, NULL, 'service', NULL, NULL, 'way/569413688', 0x00000000010200000002000000f60e12fdb5425e40a0ea460ec7652d40a64819ccba425e40c6b82c70c3652d40),
(438, 'L. Figueroa Compound', 'residential', NULL, NULL, 'way/569414426', 0x00000000010200000002000000a33616b9cc425e409e7f16a64a672d40e5c3a2d8c0425e40236f14b424672d40),
(439, NULL, 'service', NULL, NULL, 'way/569414427', 0x0000000001020000000200000097ea5d17d9425e40aae683aff9662d40e46a6457da425e4081a90b1de0662d40),
(440, NULL, 'service', NULL, NULL, 'way/569415130', 0x00000000010200000002000000032fe9def9425e40d2263dc21f682d40b4ca4c69fd425e40f0f7302020682d40),
(441, NULL, 'residential', NULL, NULL, 'way/569415132', 0x00000000010200000005000000e97e4e41fe425e40a038807edf672d4007af0221fe425e402f5e3d38e9672d40d7a02fbdfd425e40f04dd36707682d40b4ca4c69fd425e40f0f7302020682d406da8bd2dfd425e4073e83e4a36682d40),
(442, NULL, 'service', NULL, NULL, 'way/569415133', 0x000000000102000000030000003c5d273ff3425e40fca078df42682d40d6eda29ef4425e403eb0e3bf40682d40e2500999f5425e40768d96033d682d40),
(443, NULL, 'footway', NULL, NULL, 'way/569418759', 0x000000000102000000020000000c2a60f10a435e409d4c37e4fa662d40b69d5b8d11435e4079854f841e672d40),
(444, NULL, 'footway', NULL, NULL, 'way/569418760', 0x000000000102000000020000008effa7870d435e4040ba7dfbdf662d40d83c581014435e40155e38c604672d40),
(445, NULL, 'residential', NULL, NULL, 'way/578284310', 0x000000000102000000040000000f11926085425e40298aa1e6f5692d404bfb308c85425e40e3fdb8fdf2692d4062f5471886425e400e89d6e5ef692d40f50137418a425e40778604e7e7692d40),
(446, NULL, 'track', NULL, NULL, 'way/587608523', 0x00000000010200000003000000f1bc546c4c4a5e40b332d06ba2392c4024905c48514a5e40fba3b95f4f392c40ac843820534a5e40219d70653f392c40),
(447, NULL, 'path', NULL, NULL, 'way/587608527', 0x00000000010200000005000000bcd28d0b624a5e407562c55f49382c40d6a2aaae684a5e40268e3c1059382c400c299a62694a5e405fe5756968382c40481c0d3b674a5e404acdc3ae92382c406c239eec664a5e40b19c2919a5382c40),
(448, NULL, 'path', NULL, NULL, 'way/587608528', 0x000000000102000000080000007e7a223e664a5e40dd0c37e0f3372c40fcb5ab46654a5e40b07e220505382c40e5efde51634a5e40038c78fc28382c406e7a617c624a5e405f7cd11e2f382c406f073422624a5e4019726c3d43382c40bcd28d0b624a5e407562c55f49382c40f8ab5b98604a5e40a62c9ed55d382c40b2c0b22d5e4a5e40525a24928d382c40),
(449, NULL, 'residential', NULL, NULL, 'way/587608530', 0x0000000001020000000a00000097e8876c7b4a5e402a8c2d0439382c404b9ccbc3784a5e402d5c566133382c405e3ea3be764a5e404efd721c2e382c40c499ba86744a5e40399105f126382c40908c30a0724a5e406d1915dd1f382c40020ccb9f6f4a5e407229f8b715382c407e7a223e664a5e40dd0c37e0f3372c40788c3c5a664a5e40a2258fa7e5372c40296a1fe16a4a5e40a6badb508c372c40e6e4ea6c6d4a5e40b5d48beb29372c40),
(450, NULL, 'path', NULL, NULL, 'way/587608557', 0x00000000010200000005000000459e245db34a5e40205d6c5a29382c406af008b8b14a5e407db262b83a382c404daf8339b04a5e40f81510ff55382c408915246cae4a5e40602239f471382c40b985538bad4a5e4065b1a8e38c382c40),
(451, 'Green Avenue', 'residential', NULL, NULL, 'way/591023856', 0x0000000001020000000c000000d5c5127b8d425e40c443183f8d672d409477c4d78d425e400ca029858a672d403ae7a7388e425e40cda89e7186672d407480bb4791425e408ea2186a5e672d4020a79ebb93425e4016574bf03c672d4024ffdd4c96425e4034d18cea19672d4065d12ae997425e40c78ca66906672d405f3f694d98425e408f029f7aff662d404759bf9998425e40a5710399f8662d4011154fe298425e4038da71c3ef662d40c477071d99425e4066ed0099e7662d40e1174d1d9a425e40d700005bb9662d40),
(452, 'Fern Street', 'residential', NULL, NULL, 'way/591023857', 0x000000000102000000040000004759bf9998425e40a5710399f8662d4055a3570394425e40d721ed35f3662d40dd94f25a89425e409c621faee6662d40fd8e972485425e40c87dab75e2662d40),
(453, NULL, 'service', NULL, NULL, 'way/591023858', 0x0000000001020000000400000021e9d32a7a425e404e7ff62345682d40ded9684a7c425e407c79a63c5f682d4029bb4f4475425e40d663117981682d40cbd2f31373425e40cccfb29366682d40),
(454, NULL, 'service', NULL, NULL, 'way/591023859', 0x00000000010200000008000000c4d55cc969425e4056116e32aa682d40f25025146c425e40379325299f682d4040d4c78d6c425e409126de019e682d4004d083166d425e40d3156c239e682d40a45181936d425e40d84235ca9f682d4045bc75fe6d425e405fbeabd4a2682d40d298ff4671425e40344289e0c9682d406c6e96dc72425e40266b798ac1682d40),
(455, 'B. Evangelista Drive', 'residential', NULL, NULL, 'way/591024218', 0x00000000010200000003000000d791d90f67425e400112f2e615682d40f534bb4967425e404deb803518682d40281fcc376c425e40146289624d682d40),
(456, 'B. Evangelista Drive', 'residential', NULL, NULL, 'way/591024219', 0x000000000102000000040000001741086d5e425e40ae5f556243682d40196dfa5866425e409647927b15682d401ffc1fbb66425e4061aa99b514682d40d791d90f67425e400112f2e615682d40),
(457, NULL, 'service', NULL, NULL, 'way/591209652', 0x00000000010200000002000000c7ce801f7a425e408adc1d6338682d40f2fadd8577425e4083609f4a17682d40),
(458, NULL, 'service', NULL, NULL, 'way/591209653', 0x000000000102000000020000008bb0975c7b425e40158c4aea04682d402c3531137b425e406b82a8fb00682d40),
(459, 'Sugar Bird Street', 'residential', NULL, NULL, 'way/591214273', 0x00000000010200000003000000beab79e981425e4008ffc7ae59672d40bec51e3581425e40ea8e6a7d36672d402a2389b97f425e40ca92944fea662d40),
(460, NULL, 'residential', NULL, NULL, 'way/591214275', 0x00000000010200000003000000d15f43cb95425e4003e4f0ee6d672d4034d18cea99425e409fe8baf083672d40a5b7e45d9a425e40bc71f7de84672d40),
(461, NULL, 'residential', NULL, NULL, 'way/591214276', 0x0000000001020000000200000014611e8d9e425e4040530a1577672d40891dd7d097425e40653acf3351672d40),
(462, NULL, 'residential', NULL, NULL, 'way/591214278', 0x00000000010200000002000000a9dbd9579e425e406b3bb71a23672d407cce82f5a4425e404534153d4b672d40),
(463, NULL, 'residential', NULL, NULL, 'way/591214279', 0x0000000001020000000a000000a5b7e45d9a425e40bc71f7de84672d4075a675c09a425e40c87bd5ca84672d40e09ee74f9b425e40dad2591c84672d4014611e8d9e425e4040530a1577672d400c4d2377a2425e40841db57867672d40b8bbbd5aa4425e40a62666625f672d401dc64906a5425e406072a3c85a672d40abc54c47a5425e400a3f822c55672d40ffac9e38a5425e402ae09ee74f672d407cce82f5a4425e404534153d4b672d40),
(464, NULL, 'residential', NULL, NULL, 'way/591214280', 0x0000000001020000000b000000327788da91425e40c630276893672d40d2f5e91d93425e40dbc765378e672d401a468b7d93425e401ed7d0178c672d40d15f43cb95425e4003e4f0ee6d672d40891dd7d097425e40653acf3351672d405e503aec99425e405194957032672d401c19f55a9a425e40197a1fa22c672d4034411e0b9b425e4021bfc81528672d407b8e23319c425e4065ee10b523672d4032665c829d425e4012c8db0022672d40a9dbd9579e425e406b3bb71a23672d40),
(465, NULL, 'service', NULL, NULL, 'way/591214281', 0x000000000102000000020000000f6db6a885425e40799dc36b4d692d40f8acc66d8f425e40fd61f0d533692d40),
(466, NULL, 'service', NULL, NULL, 'way/591214282', 0x00000000010200000002000000c58954bda1425e40928c41ccca672d40f8a41309a6425e406dcc4642b6672d40),
(467, 'Ruby Street', 'residential', NULL, NULL, 'way/591256891', 0x000000000102000000020000009eb4705985425e40d55a988576662d40fe66bd7383425e408b225ae14c662d40),
(468, NULL, 'service', NULL, NULL, 'way/591256893', 0x000000000102000000040000005549096671425e40c653eaed2a672d4086329e526f425e4039341b1a05672d4098fc4ffe6e425e40a7165b52ff662d40dfc5562b6e425e40d9c644eff9662d40),
(469, NULL, 'service', NULL, NULL, 'way/591256894', 0x0000000001020000000200000059f78f8568425e40d2df4be141672d40b49080d165425e40dced1fb017672d40),
(470, NULL, 'service', NULL, NULL, 'way/591257532', 0x000000000102000000030000000ed539abaa425e40929b3cc0ee672d402d3cd45ba8425e40f4a96395d2672d40f8a41309a6425e406dcc4642b6672d40),
(471, NULL, 'service', NULL, NULL, 'way/591257533', 0x000000000102000000020000007ea1ecd2ab425e40f19f6ea0c0672d402d3cd45ba8425e40f4a96395d2672d40),
(472, 'F. Ibarra Street', 'service', NULL, NULL, 'way/591257534', 0x0000000001020000000300000081cd3978a6425e401c695f2f03682d400ed539abaa425e40929b3cc0ee672d400135b56cad425e4086bc2f78e2672d40),
(473, NULL, 'service', NULL, NULL, 'way/591259280', 0x000000000102000000020000006db2a1f6b6425e40f34fba3ebd672d402da17197b3425e404a69ec01a9672d40),
(474, NULL, 'residential', NULL, NULL, 'way/591259282', 0x00000000010200000004000000a9fe9cddb5425e40c5591135d1672d406db2a1f6b6425e40f34fba3ebd672d40ae878accb7425e408720bd97b1672d4024e36256b9425e403586efb380672d40),
(475, NULL, 'service', NULL, NULL, 'way/591269950', 0x00000000010200000004000000a7d887abb9425e4044f57b07e4672d40537534b3bb425e40280a99d0c9672d4076036097bc425e408e626f18bb672d408c6a6c0abf425e4066a3737e8a672d40),
(476, NULL, 'service', NULL, NULL, 'way/591269952', 0x000000000102000000030000007470fac4cb425e40c6bd9e54a0672d40c08ea449ce425e4075649b0aa7672d40b40b6190cf425e404c2723788d672d40),
(477, NULL, 'service', NULL, NULL, 'way/591269955', 0x000000000102000000040000006437d8405f425e402503401537662d40bdad4f945f425e405b83520f2c662d40f392ffc95f425e40e2e1e24d23662d40eda419e65f425e4005c3b98619662d40),
(478, NULL, 'service', NULL, NULL, 'way/591269956', 0x000000000102000000020000005c9ce73e6f425e40f8d802e731672d408dfb45bf6c425e4016365e1503672d40),
(479, NULL, 'service', NULL, NULL, 'way/591269957', 0x00000000010200000002000000a5cae6606c425e408c41711129672d40cac0a6736a425e4060cf32e609672d40),
(480, NULL, 'service', NULL, NULL, 'way/591269958', 0x000000000102000000020000005ef3aace6a425e402a5e1be038672d403c54ae4b68425e40e69a5d5210672d40),
(481, NULL, 'service', NULL, NULL, 'way/591269960', 0x00000000010200000006000000097140a690425e40063e50b868662d40bcd3f8e090425e40103345ca60662d4009579b5a91425e40d76b7a5050662d40e5c5d33c91425e40dd0bcc0a45662d407cf376df8c425e4044ac59c235662d4036785f958b425e4046ec134031662d40),
(482, 'Quartz Street', 'residential', NULL, NULL, 'way/591281701', 0x00000000010200000003000000e2500999f5425e40768d96033d682d407b4e7adff8425e4095568d6f39682d406da8bd2dfd425e4073e83e4a36682d40),
(483, 'S. Francisco Street', 'residential', NULL, NULL, 'way/591281712', 0x000000000102000000020000001763601dc7425e404e582c8f7f682d405a1943efc3425e403b01a83d80682d40),
(484, 'Saint Peter Street', 'residential', NULL, NULL, 'way/591281713', 0x000000000102000000030000004df2c8c4d2425e4050a6762bf0662d402030c50bd8425e40db8b683ba6662d40ef5701bedb425e409cb0b3d771662d40),
(485, 'Diamond Avenue', 'residential', NULL, NULL, 'way/591281716', 0x0000000001020000000a00000035f6db8df4425e402ebcdc71d4672d407ce184f8f6425e405677d1fcd6672d40436e2b62fd425e403bbbc678de672d40e97e4e41fe425e40a038807edf672d40b22e6ea301435e403953324ae1672d409382b8bc03435e409c2b9496db672d40cd63833b06435e40b2028de3d1672d40d86729b407435e40e5fa2df0cb672d4011f868160d435e40ebc5504eb4672d405e4a5d320e435e40511b30a3b3672d40),
(486, 'Prada Street', 'residential', NULL, NULL, 'way/591281722', 0x0000000001020000000c000000ab7823f3c8425e407e6bcc90cf682d40f857eab4c9425e408a75aa7ccf682d40a04fe449d2425e406c14483fd0682d4029d42e01d3425e402420cb27d0682d406d0f8ccdd8425e40781e262bd0682d4026016a6ad9425e40d7265f1ad0682d40962cdd13da425e40781e262bd0682d40acb827fede425e40ad03d660d0682d40e715f483df425e40b90db44cd0682d408ba141afe4425e40e9ed748cd0682d40977a713de5425e4048f6ad7bd0682d404d60dff3e8425e4036e7e099d0682d40),
(487, 'Rosal Street', 'residential', NULL, NULL, 'way/591282125', 0x0000000001020000000400000090c4268dac425e40e08b8a9356672d40fe7b9521b3425e40f127cf6163672d407550d378b3425e40df18028063672d402de68ccdb3425e40eb6a97db62672d40),
(488, NULL, 'service', NULL, NULL, 'way/591348895', 0x00000000010200000002000000a85bd141f2425e40d6ec37c945672d40843d377ef2425e40e909f0822d672d40),
(489, NULL, 'service', NULL, NULL, 'way/591348896', 0x00000000010200000002000000fe04bc71f7425e408db3e908e0662d407ccd1720f6425e401ee7919ad1662d40),
(490, NULL, 'service', NULL, NULL, 'way/591348897', 0x000000000102000000020000007830bd58f3425e4020c6b5ebef662d406cb64d4cf2425e403875d487e4662d40),
(491, NULL, 'service', NULL, NULL, 'way/591348899', 0x00000000010200000002000000ab4e18def6425e40f521b94615672d40008459b2f4425e403767e9affc662d40),
(492, NULL, 'service', NULL, NULL, 'way/591348900', 0x00000000010200000002000000de324c12f0425e40f9c907f30d672d400900e9f6ed425e40bd152e50f7662d40),
(493, NULL, 'service', NULL, NULL, 'way/591348901', 0x00000000010200000003000000e22b706800435e401b344f09e3662d4091e0fc3cfc425e402d173b2bb3662d4085f0c39cfb425e405405fe4bad662d40),
(494, NULL, 'service', NULL, NULL, 'way/591352162', 0x000000000102000000040000002618ce354c425e4013471e882c662d406f5a3a304a425e405f8143030c662d40b6099c114a425e40fb761211fe652d40803221414c425e40827bf9f8df652d40),
(495, NULL, 'service', NULL, NULL, 'way/591354554', 0x0000000001020000000300000093f8815003425e40c1caa145b6672d40a04db3e501425e4051e1630b9c672d40420ccfa6fe415e4016a4198ba6672d40),
(496, NULL, 'service', NULL, NULL, 'way/591354555', 0x0000000001020000000200000026a6b0f707425e4080de0a17a8672d40803c050a06425e40f306f3b281672d40),
(497, NULL, 'service', NULL, NULL, 'way/591356170', 0x00000000010200000003000000c76fc09dfa415e407d299721e9662d401494a295fb415e40e9d907b4cf662d40a3efc91efc415e404ae53796c1662d40),
(498, NULL, 'service', NULL, NULL, 'way/591356171', 0x00000000010200000007000000490e7d1cf2415e40ce041e73f9662d40fe012038f8415e4092a7f63306672d406e6f12def9415e40494be5ed08672d403ee53d73fb415e403137291609672d405b99f04bfd415e40968c086b08672d40001aa54bff415e40f23f9e0205672d4069cfc02305425e408680327cfa662d40),
(499, 'Bougainvilla Street', 'service', NULL, NULL, 'way/591358633', 0x000000000102000000030000006bbccf4c8b415e40e863e3665d682d40e5d6ff9485415e4006b75acc74682d40d7135d177e415e40d268177893682d40),
(500, NULL, 'footway', NULL, NULL, 'way/591361801', 0x00000000010200000003000000a3e9ec64f0415e4018e9ea330c682d40dc7cc800f5415e40e8dd585018682d4075779d0df9415e40958c52f822682d40),
(501, NULL, 'footway', NULL, NULL, 'way/591361802', 0x00000000010200000003000000fe744d92f8415e40600c40fe2d682d40be94cb90f4415e40d67be01923682d400856d5cbef415e4030f2b22616682d40),
(502, NULL, 'footway', NULL, NULL, 'way/591361803', 0x000000000102000000030000001adb6b41ef415e40857588241f682d40ade4be30f4415e4007e11b542c682d40feea1626f8415e40c099f3e736682d40),
(503, NULL, 'footway', NULL, NULL, 'way/591361804', 0x00000000010200000003000000bd5a4986f7415e4038abf4c940682d409518bac8f3415e40bbdcbb6136682d4003e154b5ee415e40c8e9904028682d40),
(504, NULL, 'footway', NULL, NULL, 'way/591361805', 0x0000000001020000000a000000c1334690ef415e40081edfde35682d4042a7316bf3415e4098fbe42840682d40c9daf005f7415e40f23bf2ac49682d40bd5a4986f7415e4038abf4c940682d40feea1626f8415e40c099f3e736682d4099ddee40f8415e400e6b854435682d40fe744d92f8415e40600c40fe2d682d4075779d0df9415e40958c52f822682d40271f717ef9415e40e795a1e018682d408203b573f5415e407c66a4390d682d40),
(505, NULL, 'footway', NULL, NULL, 'way/591361806', 0x0000000001020000000b000000a7800fb9f4415e403a2b5899df672d40478fdfdbf4415e40f42be79ce9672d4006baf605f4415e4019349996fd672d405fe8b6e9f4415e40f245d67503682d40e20bee62f5415e40a9119fe007682d408203b573f5415e407c66a4390d682d40dc7cc800f5415e40e8dd585018682d40be94cb90f4415e40d67be01923682d40ade4be30f4415e4007e11b542c682d409518bac8f3415e40bbdcbb6136682d4042a7316bf3415e4098fbe42840682d40),
(506, NULL, 'service', NULL, NULL, 'way/591361810', 0x000000000102000000080000002aa913d0c4415e4014121f8e64692d40189a46eec4415e40a47f93b76d692d401eb63ef6c4415e40dac9e02879692d40360f1604c5415e402d76a0f3bf692d40006f8104c5415e40e3f9b1eec4692d40f44d9a06c5415e4063258ba0d6692d405456d3f5c4415e4036c24769db692d4095d233bdc4415e40dbc6fa61df692d40),
(507, NULL, 'service', NULL, NULL, 'way/591361811', 0x000000000102000000090000008341e3d3ad415e4081b79b3b55692d40dcb75a27ae415e402aac545051692d4006c13e95ae415e403119d8744e692d404d840d4faf415e4056574ff74b692d4076172829b0415e40981e03684a692d409762fd55b6415e403849980e42692d40f5c6ffd3c3415e4093b76d2931692d400089cb96d1415e402553aae91f692d40117b57f3d2415e40d32c75351e692d40),
(508, 'Tamarind Street', 'service', NULL, NULL, 'way/591361812', 0x0000000001020000000e000000a1134207dd415e408e548440d3672d403164d064da415e40560850f811682d40cef28645d6415e40efc27bb372682d40b1868bdcd3415e405e9ece15a5682d40b2d47abfd1415e40b9e2e2a8dc682d40e82ff488d1415e4063145f48e2682d40dcb2e842d1415e40d03b5ffde9682d4059ebd511d1415e4001a19a37f3682d402a503008d1415e40503f5efef9682d400089cb96d1415e402553aae91f692d4053c9a596d2415e404dd5e2f846692d40703e75acd2415e40284fb4064a692d40ca41bfa5d2415e40bbd408fd4c692d40fa974979d2415e40d7851f9c4f692d40),
(509, NULL, 'footway', NULL, NULL, 'way/591361813', 0x0000000001020000000200000086ff740385415e402022da33f0682d40dd3532d989415e409b59a6badb682d40),
(510, NULL, 'service', NULL, NULL, 'way/591365895', 0x00000000010200000005000000ef8513e2db415e40ad5e8fd321692d40dc73aac6dc415e40dbc4c9fd0e692d40b3ddf3b2dc415e4018ef22a70a692d407eb6c480db415e403583537a01692d402529441bdb415e4014fb157ce4682d40),
(511, NULL, 'residential', NULL, NULL, 'way/591365897', 0x0000000001020000000c000000ec14ab06e1415e40ce5a65016e692d4058b49487e0415e408a52e7f637692d4058868263e0415e4010b9742733692d4076711b0de0415e4035cf11f92e692d408e29b39cdf415e40ba5d79da2b692d4017cb3ed9de415e4050b3f62d29692d40ef8513e2db415e40ad5e8fd321692d403253ffc5d8415e409f3fc80d1a692d40ce2335a3d5415e409725f03d12692d40ec6d8eced4415e401bdc31d010692d405eb642fdd3415e40e0f192a410692d40f378b537d3415e401b947a6011692d40),
(512, 'Ruby Street', 'residential', NULL, NULL, 'way/591365898', 0x00000000010200000002000000cc79c6bee4415e408c80af8d1d692d4066666666e6415e40256c89a6fd682d40),
(513, NULL, 'footway', NULL, NULL, 'way/591366461', 0x00000000010200000002000000a00d0a94de415e40bccf4c8b55662d40f48d4358e8415e4054c72aa567662d40),
(514, NULL, 'footway', NULL, NULL, 'way/591366462', 0x00000000010200000003000000f48d4358e8415e4054c72aa567662d40e9f92e00e8415e40012e6ddd72662d404eab329de7415e4030e35c797f662d40),
(515, NULL, 'footway', NULL, NULL, 'way/591366464', 0x00000000010200000002000000bb1f01edd8415e4033141c0357662d40e9f92e00e8415e40012e6ddd72662d40),
(516, NULL, 'service', NULL, NULL, 'way/591371400', 0x000000000102000000030000000f8c721fef415e4085059c4aab6a2d40d5096822ec415e406215ca1d916a2d40f9a303ede9415e401c94d519846a2d40),
(517, NULL, 'service', NULL, NULL, 'way/591371402', 0x000000000102000000030000000c44aa8317425e4084b1cfad216a2d40f33d23111a425e404c0ae2f20e6a2d40b7ac0cf41a425e40d2489572086a2d40),
(518, NULL, 'service', NULL, NULL, 'way/591371403', 0x000000000102000000030000000734c7a821425e40adfc3218236a2d40b7ac0cf41a425e40d2489572086a2d409af8591b19425e4029ef3e22016a2d40),
(519, NULL, 'service', NULL, NULL, 'way/591371408', 0x00000000010200000002000000168fe62304425e40794b283394692d4012859675ff415e409412279c82692d40),
(520, NULL, 'service', NULL, NULL, 'way/591371409', 0x00000000010200000002000000bd7acb8b02425e409dd090966f6a2d401106f93402425e407ef49727216a2d40),
(521, 'Jade Street', 'residential', NULL, NULL, 'way/591371412', 0x000000000102000000060000001138126830425e40089a852cc1682d405e5f909930425e403d8a2947b7682d40ed478ac830425e408341e3d3ad682d40abcb290131425e407f1711209e682d404cc3f01131425e40c209963490682d40c3c8dcc630425e403c9f01f566682d40),
(522, NULL, 'service', NULL, NULL, 'way/591371414', 0x0000000001020000000300000029266f8019425e4084c5973f95692d40cf6740bd19425e408323377980692d40e44fafef1e425e40e560360186692d40),
(523, 'Libra Street', 'residential', NULL, NULL, 'way/591371415', 0x000000000102000000060000005494a69c0a425e409ce73eef7c692d4090f7aa9509425e404811be9c7e692d401f9e25c808425e4016f142df82692d40fc54151a08425e40720976b28a692d40cc2f39a407425e408aca863595692d408b12995e07425e40d9f9c8f7d6692d40),
(524, NULL, 'service', NULL, NULL, 'way/591371729', 0x00000000010200000005000000b5e276c311425e406d7d47437c6a2d400380be8811425e4078921914726a2d40df05007d11425e40460d011b6b6a2d4021c77b7a11425e404c659b65606a2d40aa937da111425e406654747f506a2d40),
(525, NULL, 'service', NULL, NULL, 'way/591371730', 0x00000000010200000004000000658396bf0c425e40e3c116bb7d6a2d40f33ae2900d425e40c4f41840536a2d401c72d8220e425e40afbe709d356a2d409f67fd770e425e4094580861246a2d40),
(526, NULL, 'residential', NULL, NULL, 'way/591374828', 0x00000000010200000002000000610b30e2f1415e402529441bdb6a2d40f9eb5fa3f6415e407d6d4782ba6a2d40),
(527, NULL, 'residential', NULL, NULL, 'way/591374829', 0x00000000010200000003000000a7b1bd16f4415e40207efe7bf06a2d40610b30e2f1415e402529441bdb6a2d4045a56ceced415e40e01dcf1db36a2d40),
(528, 'A. Ramirez Street', 'residential', NULL, NULL, 'way/591374830', 0x0000000001020000000200000079c663abf0415e40edda3928bc6b2d401df3f054f6415e40baed8c00b86b2d40),
(529, NULL, 'residential', NULL, NULL, 'way/591374831', 0x00000000010200000004000000ed9f02bbf5415e4012537d42d16b2d401131cad8f5415e400529c297d36b2d404ded56e0f5415e4051ba9976d66b2d4035ae241ef5415e40f9bd4d7ff66b2d40),
(530, NULL, 'service', NULL, NULL, 'way/591482674', 0x000000000102000000030000004974e0e69e415e405eadc909c96c2d4059294effa3415e401eba4505f36c2d405dc30c8da7415e405d137761106d2d40),
(531, NULL, 'service', NULL, NULL, 'way/591482678', 0x00000000010200000010000000793f6ebf7c415e40b5577ac8ef6c2d409cfe47017d415e40348e475ff76c2d4078e0ad3d7d415e4038537cd7fb6c2d4055f0259e7d415e4030e6f8b2fe6c2d404e8c76267e415e40827cbf87016d2d4012013dc38a415e407cce82f5246d2d4097dd38ce92415e4019f329b6386d2d401c61acca99415e40f2b1bb40496d2d406f7374a69a415e40103bf82e4a6d2d4087b2a6689b415e40e1325d3e486d2d40876aeff89b415e407ff55db6426d2d405cd19cab9c415e4058a2fd593d6d2d401a69a9bc9d415e40dce8adcb3a6d2d40383701e19e415e40ac08ed8b3a6d2d405b0a48fb9f415e40fe9eb3603d6d2d40b9b0242fa1415e40476062e2456d2d40),
(532, 'Saint Matthew Street', 'residential', NULL, NULL, 'way/591482680', 0x000000000102000000050000007b46c77a8f415e40ef49719f666e2d405de5643d90415e403bbe62b25d6e2d402debfeb190415e40f3d4d97f536e2d407b88467790415e40dee3f159436e2d4099bb96908f415e4083d9a95e236e2d40),
(533, NULL, 'service', NULL, NULL, 'way/591482681', 0x000000000102000000050000002aabe97aa2415e40dccfce0e5d6d2d4077b8c260a3415e409add49fa6a6d2d404762388da3415e40dfd9c3036f6d2d4017f5a4a7a3415e4066c5cb2e736d2d40ce058948a8415e4025dc7580716e2d40),
(534, 'Pablo dela Cruz Street', 'residential', NULL, NULL, 'way/591483174', 0x0000000001020000000c000000e8fb04abc5415e4024873e0e396c2d40b796c970bc415e40d97bf1457b6c2d409bcb0d86ba415e4061ec736b886c2d4024cc5944b9415e4086ff194a926c2d405857056ab1415e40c7c7ddd6cc6c2d40600fdc37ad415e40b6e7e8a7ee6c2d40ced77624a8415e409bea24b6166d2d4048f542a6a1415e40023917354e6d2d4078ad2935a0415e40a1759ec25b6d2d40f17332279e415e403895568d6f6d2d403bdf4f8d97415e407dda9722af6d2d40794b283394415e40c1f00005cd6d2d40),
(535, NULL, 'service', NULL, NULL, 'way/591625237', 0x000000000102000000040000004f441a7071425e4038ff0af4e4692d40dd54ee4f73425e40b4bb5175d9692d40f9d7f2ca75425e4010520141ca692d40cf97288c77425e40c8b02f7ebf692d40),
(536, NULL, 'service', 'yes', NULL, 'way/591625238', 0x00000000010200000003000000c31a1d4677425e4031bb82c87d6a2d40f3171f0b76425e40c514f6fe506a2d4030f1ec9774425e40ce2dbeb21c6a2d40),
(537, NULL, 'service', NULL, NULL, 'way/591625240', 0x00000000010200000005000000296dbb1a6a425e401cc17c68d5692d4087f656c96c425e40ef93feb9c3692d4002092f6670425e400336316eb4692d40fa36b34c75425e402642d94a9e692d408ec5dbef75425e40128eb4af97692d40),
(538, 'Violet Street', 'residential', NULL, NULL, 'way/591629574', 0x00000000010200000003000000f078495208425e40d4a29982906b2d40dc74159c0b425e40234c512e8d6b2d404f84c3c114425e40285c3409836b2d40),
(539, 'Green Street', 'residential', NULL, NULL, 'way/591629576', 0x00000000010200000004000000e4c578831e425e40eb6e9eea906b2d40e56cf0741d425e408bfed0cc936b2d40e7dabc1619425e40790ceab69f6b2d407d8c5eb216425e4099caec3da66b2d40),
(540, NULL, 'footway', NULL, NULL, 'way/591633334', 0x000000000102000000030000006d6a45402a425e40f534bb49676b2d40d84812842b425e409f2c6b51556b2d405a0d897b2c425e405863bfdd486b2d40),
(541, NULL, 'footway', NULL, NULL, 'way/591633335', 0x00000000010200000003000000a42d533827425e408ee0eb10a46b2d4028e494ca25425e407a2cc7759d6b2d406d6a45402a425e40f534bb49676b2d40),
(542, 'South Luzon Expressway', 'construction', 'yes', NULL, 'way/593198169', 0x0000000001020000000700000053f2a08f684a5e40a8c821e2e63c2c40d9d4d40d6f4a5e40c3b1d3b4303c2c40967db2bd714a5e40dd0c37e0f33b2c406bc482b1744a5e40b5256195c13b2c407bf5f1d0774a5e404d6fdae78c3b2c405ce7df2e7b4a5e40cbf44bc45b3b2c406b1d6679e84a5e404facf82b09352c40),
(543, 'South Luzon Expressway', 'construction', 'yes', NULL, 'way/593198173', 0x00000000010200000007000000ca1f67f5e94a5e404b4c61ef0f352c40793f6ebf7c4a5e403fb1a94e623b2c403f4a3668794a5e40a3a2fb83923b2c402f19c748764a5e40ca69f40fc73b2c402a4e5a5d734a5e40b7f6990ef83b2c40618495af704a5e40f19991e6343c2c404de779266a4a5e40f2391c02ec3c2c40),
(544, 'South Luzon Expressway', 'construction', 'yes', NULL, 'way/593198177', 0x000000000102000000020000006b1d6679e84a5e404facf82b09352c402098a3c7ef4a5e40ebb996da9c342c40),
(545, 'South Luzon Expressway', 'construction', 'yes', NULL, 'way/593198178', 0x00000000010200000002000000a8195245f14a5e404d672783a3342c40ca1f67f5e94a5e404b4c61ef0f352c40),
(546, NULL, 'residential', NULL, NULL, 'way/593198207', 0x000000000102000000020000007a1a30487a4a5e4060cf32e609372c4043209738724a5e40f00dcf5cf1362c40),
(547, NULL, 'residential', NULL, NULL, 'way/593198208', 0x00000000010200000008000000b62110f9784a5e40cf70b9b024372c4073ecea9f714a5e4062e41bc011372c40d20ec9da704a5e402acaa5f10b372c403d66fbeb704a5e4057050f7805372c4043209738724a5e40f00dcf5cf1362c406b990cc7734a5e408b0e924fd9362c404778d6c9744a5e40eba6391ed8362c40ea8722ee7b4a5e4045042d6eed362c40),
(548, NULL, 'residential', NULL, NULL, 'way/593198209', 0x00000000010200000002000000642fca22834a5e4046e22f7777362c40071a7d16954a5e408b27710cb7362c40),
(549, NULL, 'residential', NULL, NULL, 'way/593198210', 0x000000000102000000020000000572e4dc814a5e40d39c610f92362c40d20cf32f934a5e405919e835d1362c40),
(550, NULL, 'residential', NULL, NULL, 'way/593198211', 0x00000000010200000002000000ad495c6c7f4a5e40cab95ee4af362c4092239d81914a5e40825660c8ea362c40),
(551, NULL, 'residential', NULL, NULL, 'way/593198212', 0x00000000010200000002000000842c0b267e4a5e4012c0cde2c5362c408d0dddec8f4a5e40695c93c904372c40),
(552, NULL, 'residential', NULL, NULL, 'way/593198213', 0x00000000010200000009000000d242b8b87c4a5e409f7aff7ae0362c40db3d2fcb8d4a5e40cd83aa871e372c40281df68c8e4a5e400f9315681c372c408d0dddec8f4a5e40695c93c904372c4092239d81914a5e40825660c8ea362c40d20cf32f934a5e405919e835d1362c40071a7d16954a5e408b27710cb7362c40ad0d5f70974a5e40c767b27f9e362c40b7f75f9d994a5e4051e9167085362c40),
(553, NULL, 'residential', NULL, NULL, 'way/593198214', 0x0000000001020000000b0000007c54b252774a5e4096653ed642372c40b62110f9784a5e40cf70b9b024372c407a1a30487a4a5e4060cf32e609372c40ea8722ee7b4a5e4045042d6eed362c40d242b8b87c4a5e409f7aff7ae0362c40842c0b267e4a5e4012c0cde2c5362c40ad495c6c7f4a5e40cab95ee4af362c400572e4dc814a5e40d39c610f92362c40642fca22834a5e4046e22f7777362c403f81c17f844a5e408ad7ab7e5b362c40ad0d5f70974a5e40c767b27f9e362c40),
(554, NULL, 'track', NULL, NULL, 'way/607809008', 0x00000000010200000002000000cc800e4e9f4a5e40d2246717c2382c40424f1432a14a5e40df4614a463382c40),
(555, NULL, 'track', NULL, NULL, 'way/607809010', 0x00000000010200000003000000424f1432a14a5e40df4614a463382c406419879fa44a5e40a873452921382c4022f6aee6a54a5e4039c7ca7910382c40),
(556, NULL, 'track', NULL, NULL, 'way/607809012', 0x00000000010200000003000000ae3b27077d4a5e4014ad815259392c4088878b378d4a5e40d9bbf55091392c4078144262964a5e409b3bfa5fae392c40),
(557, NULL, 'residential', NULL, NULL, 'way/607809026', 0x000000000102000000040000000667f0f78b4a5e400b0dc4b299372c406a6b44308e4a5e40117349d576372c406fe0c4468f4a5e4013ded4f665372c401b3bf251904a5e40cbd765f84f372c40),
(558, NULL, 'track', NULL, NULL, 'way/607809027', 0x000000000102000000020000007d491927744a5e4052e5c5d33c392c40ae3b27077d4a5e4014ad815259392c40),
(559, NULL, 'track', NULL, NULL, 'way/607809029', 0x00000000010200000008000000ac843820534a5e40219d70653f392c40aaee91cd554a5e40fc5ef9e241392c40c746205e574a5e40408e41823d392c40f08b4b555a4a5e40d4caceec04392c40fa754c825c4a5e40762a2a2c02392c4046bcd0b7604a5e402009fb7612392c40fbdd85f7664a5e4068fd778e12392c407d491927744a5e4052e5c5d33c392c40),
(560, NULL, 'track', NULL, NULL, 'way/609067871', 0x0000000001020000000a0000001372ef2b204a5e405f7017ab17392c4042f6306a2d4a5e407f03498e2a392c408935a671394a5e4034a1496249392c40e768fa91474a5e407b26457584392c40f1bc546c4c4a5e40b332d06ba2392c40cbee6e0a504a5e40f06b2409c2392c402d57e47c564a5e40b2c34e67dd392c400259993a594a5e40badd2637e5392c4093286a1f614a5e400d2142b7f2392c40f5375783664a5e40b5ea2928fb392c40),
(561, NULL, 'path', NULL, NULL, 'way/609633713', 0x0000000001020000001d000000240ed9403a4a5e405edb36e73b3b2c4041dc30653b4a5e40a38ff980403b2c40abce6a813d4a5e401f49490f433b2c40aff25f7b414a5e40a8740bb8423b2c40d882de1b434a5e4031a0cd60423b2c405367a494464a5e40aa89f4914a3b2c40810de3c9494a5e4050132285573b2c400a922d814a4a5e40d2d160095a3b2c405626a1994c4a5e40c8242367613b2c40c0a5ad5b4e4a5e4086c20c326e3b2c405abdc3ed504a5e40584ae0206b3b2c40f34707da534a5e40da7ba7b8603b2c407a08991a574a5e40a3395739593b2c4007dfeaef5b4a5e40626aa6d6563b2c40d48a259b614a5e40d6ec37c9453b2c409303d1ee6b4a5e40f5914a67163b2c40c86f1b576d4a5e40f23f9e02053b2c408c2320706e4a5e40e253a5d2f43a2c4074deb53a6f4a5e4019afd40eda3a2c40eac6606a704a5e40ea904028943a2c4061af0b9a714a5e40e601d138793a2c4085b69c4b714a5e407e326bce663a2c40b54071b66f4a5e401878ee3d5c3a2c40e2a650276a4a5e4003cfbd874b3a2c40bcd28d0b624a5e40c455af6c303a2c4063038ea9604a5e405029c0c1283a2c40d1cb28965b4a5e4002017c01073a2c402b734e475b4a5e4076830df4f5392c400259993a594a5e40badd2637e5392c40),
(562, NULL, 'track', NULL, NULL, 'way/609633737', 0x00000000010200000009000000d721ed35734a5e4020370d9b123a2c40c9d754cc774a5e4045f70725273a2c401b5aaec8794a5e402046088f363a2c40a379008b7c4a5e40fa9408f9453a2c40fbe93f6b7e4a5e40c94cb38a483a2c4023186250814a5e40beb55db23b3a2c403332c85d844a5e40e2e1e24d233a2c40c8282a768f4a5e407efe7bf0da392c4078144262964a5e409b3bfa5fae392c40),
(563, NULL, 'track', NULL, NULL, 'way/609633738', 0x00000000010200000003000000f5375783664a5e40b5ea2928fb392c401a3790896f4a5e40baa46abb093a2c40d721ed35734a5e4020370d9b123a2c40),
(564, NULL, 'service', NULL, NULL, 'way/615434615', 0x000000000102000000020000002bc313d5b6415e4060408a952c6e2d404fd834a5ab415e40324ae18b406e2d40),
(565, NULL, 'service', NULL, NULL, 'way/615434616', 0x00000000010200000006000000fcb44071b6415e405b892fc9b76d2d4027fb4223b3415e40bc36c071be6d2d404b8c0a41b3415e40ead6c633c36d2d40c2604898b3415e400d1247c3ce6d2d402bc313d5b6415e4060408a952c6e2d4078d0ecbab7415e404d9363fc456e2d40),
(566, NULL, 'service', NULL, NULL, 'way/615746688', 0x0000000001020000000200000041d47d0052415e40270fb0fb336c2d402317f77a52415e40a30cb0ea076c2d40),
(567, NULL, 'residential', NULL, NULL, 'way/615746689', 0x000000000102000000030000003c9bfae538415e400369b576916c2d408ac8b08a37415e40f836fdd98f6c2d4074da09e533415e4066193d128a6c2d40),
(568, NULL, 'service', NULL, NULL, 'way/615746691', 0x000000000102000000020000006dad2f125a415e4094837e4ba56c2d40771ecb715d415e40e05c0d9aa76c2d40),
(569, 'Saint Joseph Street', 'residential', NULL, NULL, 'way/615752343', 0x00000000010200000002000000bcd5ce8b6e415e4021ee450fd76d2d40981991836d415e406cc0d65bb96d2d40),
(570, NULL, 'service', NULL, NULL, 'way/616814874', 0x000000000102000000020000007554da8761415e40cfdc9e7b6a6c2d40bc1a457b61415e40c2dabd816e6c2d40),
(571, NULL, 'service', NULL, NULL, 'way/616817927', 0x00000000010200000004000000cadc7c23ba415e40102ed3e5836c2d406885d84fb5415e40bc7e1c284b6c2d405d8132d7b3415e408737c6a9316c2d40043f051bb2415e40e0c38080106c2d40),
(572, NULL, 'service', NULL, NULL, 'way/616817928', 0x00000000010200000008000000516b9a779c415e40b8f6f4c76a6d2d40fe2ac0779b415e40d65757056a6d2d40a5e5f6819a415e403a8d599b6b6d2d400508d5bc99415e401b0c1a9f6e6d2d40f39f7fcc98415e40737ff5b86f6d2d4097f7dd1992415e40e86624e7696d2d401b947a6091415e408a0e3796666d2d40e04db7ec90415e4088b1964c5f6d2d40),
(573, NULL, 'service', NULL, NULL, 'way/616817929', 0x000000000102000000020000001045dcf783415e402ddad2591c6c2d401661d4ff83415e403d1c6ed1136c2d40),
(574, NULL, 'service', NULL, NULL, 'way/616817930', 0x000000000102000000030000000583103576415e408b3acec87b6c2d40c13687107c415e4006d44098806c2d407ece93217d415e40159f4ced566c2d40),
(575, NULL, 'residential', NULL, NULL, 'way/616817931', 0x0000000001020000000200000001cf0715e6415e4098f90e7ee26c2d4043aa285ee5415e40ed7ce47beb6c2d40),
(576, 'Aratilis Street', 'residential', NULL, NULL, 'way/616817932', 0x000000000102000000020000009b502dc7d0415e40d18cea19676c2d40a1b4dc3ed0415e40c2dabd816e6c2d40),
(577, 'Atlas Interior', 'residential', NULL, NULL, 'way/616817933', 0x00000000010200000011000000e757ce39d3415e4022bb1cc06c6c2d4052dd126fd3415e40c73258cc636c2d40cf577f3ad4415e408813f3075e6c2d40c28c8411d6415e409c429da85b6c2d40df88ee59d7415e40f258d878556c2d40e45993b8d8415e4062331bbf4b6c2d4078cb7ad6da415e4030664b56456c2d401d77a5c0dd415e4010806e1e3d6c2d4022e6ed63e0415e400e23ced4356c2d40a4349bc7e1415e4094895b05316c2d408cec9458e3415e40435b295f2b6c2d402c5789c3e3415e40273a819f276c2d40bb849e28e4415e40bacac97a206c2d4056bc9179e4415e40d61643de176c2d40f6f873c0e4415e4092825d03116c2d40a9a04731e5415e4060fd440a0a6c2d40d8385101e6415e406a62cb3c036c2d40),
(578, NULL, 'service', NULL, NULL, 'way/616831058', 0x000000000102000000020000003acf33515f415e408ed20039bc6b2d401669e21d60415e407dc2233b806b2d40),
(579, NULL, 'service', NULL, NULL, 'way/616831060', 0x000000000102000000050000004974e0e69e415e405eadc909c96c2d40b69267a89b415e407086d162df6c2d40a55824dc9a415e4099897d5de16c2d40dbfb54159a415e4017cb3ed9de6c2d40b6b700d990415e4007150b32b86c2d40),
(580, NULL, 'service', NULL, NULL, 'way/616831062', 0x00000000010200000006000000b69267a89b415e407086d162df6c2d406da34b49a0415e405be1a7bbfc6c2d40ef22a70aa1415e40b719b84d026d2d400679e2dea1415e40539cfe47016d2d4059294effa3415e401eba4505f36c2d400c84ae8ead415e40715af0a2af6c2d40),
(581, NULL, 'residential', NULL, NULL, 'way/616831064', 0x00000000010200000007000000ecf42801d6415e4003f3ebe2916b2d40586fd40ad3415e404eba884a7e6b2d40e801e264d1415e400adeebff776b2d40ea58a5f4cc415e40b82a3f5f696b2d402d205965cb415e40f414de8a696b2d402fea494fc7415e40b90265ae676b2d40849554b7c4415e40d5be6f32606b2d40),
(582, NULL, 'service', NULL, NULL, 'way/617294550', 0x00000000010200000004000000137cd3f459425e40e71bd13deb6a2d40fb647be35a425e40d721ed35f36a2d402f803a2f5f425e4023186250016b2d405d6e30d461425e40e0c03f00046b2d40),
(583, NULL, 'service', 'yes', NULL, 'way/617294551', 0x0000000001020000000d000000fd1d407562425e4045f64196056b2d403cb60a0767425e4047b87f1b186b2d40537cd7fb68425e40059e2056246b2d4040c05ab56b425e40432d173b2b6b2d40d4d51d8b6d425e400c5064f72e6b2d40afaeaf1a70425e4021246651336b2d40d164b5af72425e409e454a0e336b2d404173e7d374425e403a3b191c256b2d40ff0af4e475425e400ff4ab94f96a2d406fa6f8ae77425e40372d1d18e56a2d409939138978425e40b04c09d2d66a2d40e0ff7d7c78425e40ac87d459d26a2d4087a00f3b78425e402b114d45cf6a2d40),
(584, NULL, 'service', 'yes', NULL, 'way/617294552', 0x0000000001020000000200000032175d8363425e4069b23511ec6a2d40fd1d407562425e4045f64196056b2d40),
(585, NULL, 'service', 'yes', NULL, 'way/617294553', 0x000000000102000000020000003cb60a0767425e4047b87f1b186b2d405b5f24b465425e408fc8d2e2e76a2d40),
(586, NULL, 'service', 'yes', NULL, 'way/617294554', 0x000000000102000000020000003036638767425e40a8fc6b79e56a2d40537cd7fb68425e40059e2056246b2d40),
(587, NULL, 'service', 'yes', NULL, 'way/617294555', 0x0000000001020000000200000040c05ab56b425e40432d173b2b6b2d40a6eac31f6a425e4009b5f006e26a2d40),
(588, NULL, 'service', 'yes', NULL, 'way/617294556', 0x00000000010200000002000000823cbb7c6b425e40bddb61b8df6a2d40d4d51d8b6d425e400c5064f72e6b2d40),
(589, NULL, 'service', 'yes', NULL, 'way/617294557', 0x000000000102000000020000007fb4498f70425e40b651f8c7d66a2d40d164b5af72425e409e454a0e336b2d40),
(590, NULL, 'service', 'yes', NULL, 'way/617294558', 0x000000000102000000020000009b7631cd74425e40ad5ffaa8d06a2d40ff0af4e475425e400ff4ab94f96a2d40),
(591, NULL, 'service', 'yes', NULL, 'way/617294559', 0x000000000102000000020000004173e7d374425e403a3b191c256b2d40e9a683ab72425e4099a0e128d46a2d40),
(592, NULL, 'service', 'yes', NULL, 'way/617294560', 0x000000000102000000070000009ebfbff76d425e406c1dc132db6a2d40823cbb7c6b425e40bddb61b8df6a2d40a6eac31f6a425e4009b5f006e26a2d403036638767425e40a8fc6b79e56a2d405b5f24b465425e408fc8d2e2e76a2d402005f46764425e40178c005dea6a2d4032175d8363425e4069b23511ec6a2d40),
(593, NULL, 'service', NULL, NULL, 'way/617294561', 0x00000000010200000002000000f838d3846d425e404a928c41cc6a2d409ebfbff76d425e406c1dc132db6a2d40),
(594, NULL, 'service', 'yes', NULL, 'way/617294562', 0x000000000102000000020000002d6b515557425e409bd07f6a176a2d40f1941f0258425e40e413b2f3366a2d40),
(595, NULL, 'service', 'yes', NULL, 'way/617294563', 0x0000000001020000000200000064f2bc0a5f425e40369776c5e7692d4040fcfcf760425e40153f2196286a2d40),
(596, NULL, 'service', 'yes', NULL, 'way/617294564', 0x00000000010200000002000000d6c4a7a55e425e408a63134f2c6a2d4000ee68d25c425e40d93e8974e4692d40),
(597, NULL, 'service', 'yes', NULL, 'way/617294565', 0x000000000102000000020000005be37d665a425e406ff9a303ed692d401ec2f8695c425e406a9a1ce32f6a2d40),
(598, NULL, 'service', 'yes', NULL, 'way/617294566', 0x00000000010200000002000000cc28965b5a425e4021f6532d336a2d40de82b6e658425e401193cbda016a2d40),
(599, NULL, 'service', 'yes', NULL, 'way/617294567', 0x0000000001020000000a00000099a0866f61425e40f1475167ee692d4064f2bc0a5f425e40369776c5e7692d4000ee68d25c425e40d93e8974e4692d40e99ac9375b425e40f07a1ffde5692d405be37d665a425e406ff9a303ed692d40b58d3f5159425e4063c4f473f9692d40de82b6e658425e401193cbda016a2d402d6b515557425e409bd07f6a176a2d40c333fc0255425e409bff571d396a2d40f8ea991455425e40be45cc913a6a2d40),
(600, NULL, 'service', NULL, NULL, 'way/617294568', 0x00000000010200000002000000cc28965b5a425e4021f6532d336a2d406089acda5a425e401efb592c456a2d40),
(601, NULL, 'service', NULL, NULL, 'way/617294569', 0x00000000010200000005000000cc28965b5a425e4021f6532d336a2d401ec2f8695c425e406a9a1ce32f6a2d40d6c4a7a55e425e408a63134f2c6a2d4040fcfcf760425e40153f2196286a2d40d95bcaf962425e4052d90b60256a2d40),
(602, NULL, 'service', NULL, NULL, 'way/617294570', 0x00000000010200000002000000567a127d63425e40f0d5d86f376a2d40d95bcaf962425e4052d90b60256a2d40),
(603, NULL, 'service', NULL, NULL, 'way/617294571', 0x00000000010200000007000000875c5fda26425e4027da5548f9692d40881d7c1725425e408ad29453f1692d4094b42ca924425e40ec8a19e1ed692d402901d64f24425e40a041f971ea692d40ca6e66f423425e405ab51089e7692d40cacd267623425e4055d0fe51e5692d402a977ca221425e400b7fe1f0dd692d40),
(604, NULL, 'service', NULL, NULL, 'way/617317076', 0x00000000010200000007000000d9b1118857425e40d8351081d9672d406d54a70359425e40117b57f3d2672d4055f833bc59425e40faf609fbd1672d40b414da835a425e408927bb99d1672d4060fcd9345b425e40efc4515ed0672d40cb0b55d65b425e40aef5a0fbcd672d404738d2be5e425e40aa8317d8be672d40),
(605, NULL, 'service', NULL, NULL, 'way/617317077', 0x000000000102000000070000007a50508a56425e4072a36da1d0672d40373bad365a425e40287d21e4bc672d409c5c42f45a425e4031c2ca57b8672d4054200e6d5b425e4087489748b3672d40e90df7915b425e40301576acad672d4096e1896a5b425e40e0e64306a8672d40cec4742156425e4099a9ff626c672d40),
(606, NULL, 'service', NULL, NULL, 'way/617317078', 0x000000000102000000050000005d31c8024b425e40244d727621682d406f4095e44a425e40d6242eb6ff672d408db5bfb33d425e4088c32d7a02682d40a50e97c13d425e405c0d3fee11682d406f850bd43d425e408dd7176426682d40),
(607, NULL, 'service', NULL, NULL, 'way/617317079', 0x00000000010200000002000000a50e97c13d425e405c0d3fee11682d40b857e6ad3a425e40a3b9049612682d40),
(608, NULL, 'service', NULL, NULL, 'way/617317080', 0x00000000010200000003000000212c19b61c425e40412c9b3924692d401a97bbe01d425e40409c2c5a25692d40c653eaed2a425e40cf5955e531692d40),
(609, NULL, 'service', NULL, NULL, 'way/617317081', 0x00000000010200000003000000e411dc4859425e40faba67b85c682d4078b471c45a425e40626de75663682d40bf5afff85c425e407777ae3951682d40),
(610, NULL, 'service', NULL, NULL, 'way/617317082', 0x00000000010200000002000000a98999d857425e4036316eb42d682d40fc22fce659425e4010b633a726682d40),
(611, NULL, 'service', NULL, NULL, 'way/617317083', 0x0000000001020000000900000036374b6e39425e40b85a272ec7672d406b16c3303b425e409b19a2afc5672d402f127fb93b425e404eb0a481c4672d406a58422d3c425e40c6a4bf97c2672d405eaa88893c425e4056ad9685c0672d40eaf307b941425e401d1c919499672d405b64969842425e4096c0f74894672d4031105f8143425e40464a0e338f672d404ce3175e49425e405f44db3175672d40),
(612, NULL, 'service', NULL, NULL, 'way/642482802', 0x000000000102000000050000003cc093162e425e40f07c5061b6662d402a1087b62d425e4095641d8eae662d40f684db9035425e40284b08b18e662d40087a032736425e40e27668588c662d403dcf447d37425e400e2263ff86662d40),
(613, NULL, 'service', NULL, NULL, 'way/642482803', 0x0000000001020000000500000059bcfd5e2f425e40751daa29c9662d40481229722d425e407c87365bd4662d40b4b74a662b425e4015127a47d7662d4020a2879029425e405d4eaeced6662d407430517328425e406ef8dd74cb662d40),
(614, NULL, 'service', NULL, NULL, 'way/653381965', 0x00000000010200000004000000509ced1b29425e40b0fb33283f6a2d40975fbcd529425e4024360eab2e6a2d40c07c0d1c2b425e406006befd146a2d401fb0bcf52b425e4030a182c30b6a2d40),
(615, NULL, 'service', NULL, NULL, 'way/653381966', 0x00000000010200000009000000d0ca074e47425e403ae40bff8e692d4076a49f153d425e40863b17467a692d40525b8f673c425e403f8f519e79692d40a6738fb63b425e407a31395a7a692d404f99f62837425e40f1225d7d86692d40c659c7a736425e40ba8d61a989692d40f66a364536425e4088b59d5b8d692d40f7b589ee34425e405402bdcba0692d40c87c40a033425e40db526232b0692d40),
(616, NULL, 'service', NULL, NULL, 'way/653381967', 0x00000000010200000006000000dad605723f425e40100874266d6a2d402c595f6e41425e40b50b1703356a2d402506819543425e40d46b6924f8692d40cb6f2c8345425e402c9e7aa4c1692d40f47574b746425e405b971aa19f692d40d0ca074e47425e403ae40bff8e692d40),
(617, NULL, 'service', NULL, NULL, 'way/653381968', 0x00000000010200000005000000f7b589ee34425e405402bdcba0692d407f4ba54437425e4040b3356ca5692d40be8ae7c73a425e401f3af361ac692d40cb6f2c8345425e402c9e7aa4c1692d40e001542756425e407be69b23e1692d40),
(618, NULL, 'service', NULL, NULL, 'way/653383917', 0x0000000001020000000400000059c97d6168425e400ecc1b7112682d4024264d2869425e4028d8da560e682d4017b776476b425e40226e4e2503682d402df070966d425e40b18119f8f6672d40),
(619, NULL, 'service', NULL, NULL, 'way/653383918', 0x000000000102000000020000002df070966d425e40b18119f8f6672d40024bae6271425e40cb01710d22682d40),
(620, NULL, 'service', NULL, NULL, 'way/653383920', 0x00000000010200000006000000a75f7d972d425e40f5edc96889662d40706e5d7b30425e40ebc9fca36f662d405255b2ad30425e404c8281316c662d40bdace4be30425e40835f347568662d404c50c3b730425e4007a6e4e665662d4076b867a730425e40fd039b2963662d40),
(621, NULL, 'service', NULL, NULL, 'way/690136264', 0x00000000010200000002000000ad1f51572d425e40258ee156e6662d40481229722d425e407c87365bd4662d40),
(622, 'Saint James Street', 'residential', NULL, NULL, 'way/694203182', 0x000000000102000000030000004af14cc3cb425e4011058e5fd3662d4073501d06ce425e40cb4dd4d2dc662d404df2c8c4d2425e4050a6762bf0662d40),
(623, NULL, 'residential', NULL, NULL, 'way/743592047', 0x00000000010200000005000000748fb63bb5525e40f170f1a611112c405d11a1b6b2525e40ae36b52220112c403c365daaad525e407b78e0ad3d112c40b288bc40a4525e400d52f01472112c40d8e610829f525e40099cb69091112c40),
(624, NULL, 'residential', NULL, NULL, 'way/764400471', 0x0000000001020000000300000062ef6a5efa495e40775fdf98af382c40da9e6a3ef8495e40b18e3e41bd382c40a6bff27bf6495e409824e021d6382c40),
(625, NULL, 'footway', NULL, NULL, 'way/810395980', 0x00000000010200000002000000b504cf73fa415e40e8d0330752672d405ddc4603f8415e406fbc3b3256672d40),
(626, NULL, 'service', NULL, NULL, 'way/834266477', 0x00000000010200000003000000adb0cf5268525e40348c71b4990d2c40a886a2e565525e40c619c39ca00d2c4068a384aa62525e40cc13beadaa0d2c40),
(627, 'S. Francisco Street', 'residential', NULL, NULL, 'way/857069154', 0x000000000102000000020000005a1943efc3425e403b01a83d80682d40742502d5bf425e400b91781e81682d40),
(628, NULL, 'residential', NULL, NULL, 'way/857069701', 0x00000000010200000005000000c65c0828c3425e402c955c6a29692d400d3a7c2dc3425e40bf08bf7916692d40d899e72dc3425e40e3b6c71c15692d40deb5df35c3425e40520c906802692d403dd52137c3425e4036a33039ff682d40),
(629, 'Emerald Street', 'residential', NULL, NULL, 'way/860900720', 0x0000000001020000000400000095719d90e7415e406056cd188b6b2d40b90501e8e6415e4038d89b18926b2d400d4c135be6415e409f2287889b6b2d4067c526e8e5415e400b2aaa7ea56b2d40),
(630, NULL, 'residential', NULL, NULL, 'way/885060272', 0x00000000010200000002000000a2cfec5f7e525e40c0be8c182c0f2c402d5beb8b84525e401f7013a4080f2c40),
(631, NULL, 'residential', NULL, NULL, 'way/885060273', 0x000000000102000000020000003ba8c4758c525e400dd3ad8d670e2c4009fb761291525e408d4a45bea60e2c40),
(632, NULL, 'service', NULL, NULL, 'way/889084132', 0x0000000001020000000d000000744b6194564b5e406b2c616d8c392c40904c874e4f4b5e4035ecf7c43a392c4091c5ec1b4e4b5e40bf428b112e392c40d88ef3484d4b5e40b57867a329392c40d305065a4b4b5e40abae433525392c40ce03b39d4a4b5e40930a197e26392c4093a98251494b5e408358ece52d392c40e1606f62484b5e40992cee3f32392c4064fd0ba9474b5e40bc7262b433392c406bf12900464b5e40a051baf42f392c4048217f1f444b5e406a77fea325392c4075875e903e4b5e40889a8d3adf382c40fe3ff3de3d4b5e40841d1032da382c40),
(633, NULL, 'service', NULL, NULL, 'way/889084133', 0x0000000001020000000500000082f057b7304b5e40146faeab13392c4006bea25b2f4b5e4069b8b71105392c40420a9e422e4b5e409ad832cf00392c4007239b502d4b5e404d970f5201392c4043fc68dd2b4b5e407b0f3c6304392c40),
(634, NULL, 'service', NULL, NULL, 'way/889084134', 0x0000000001020000000400000010b633a7264b5e401f4ebbf31f392c40c97c9b59264b5e406bcda0eb0c392c402e008dd2254b5e40bf863b72ff382c40dd9d1095214b5e403222ac21cc382c40),
(635, NULL, 'service', NULL, NULL, 'way/889084135', 0x000000000102000000080000008f064bd03a4b5e40f5392d2e44392c40f8b0cd7c3d4b5e406db0cb4b59392c4010913fbd3e4b5e40617b1cbc65392c4057540e773f4b5e401d041dad6a392c40af963b33414b5e403b3aae4676392c409d3fb7e1414b5e4037925f9a7d392c4007bfc3a3434b5e40f7a9cf7a9d392c408a3e1f65444b5e40bbb14577b5392c40);
INSERT INTO `streets` (`Id`, `Name`, `Highway`, `Oneway`, `OldName`, `StreetId`, `Geometry`) VALUES
(636, NULL, 'service', NULL, NULL, 'way/889084136', 0x00000000010200000009000000b631d17b3e4b5e4002f96de3aa392c409e31827c3f4b5e4077f28ef8ba392c40c8c738903f4b5e402e967db2bd392c40bc783f6e3f4b5e40681888afc0392c40b840dd9b3a4b5e40a281b3efe5392c401ec4ce143a4b5e40f1ff99f7ee392c4012e8024d3a4b5e4044639236fa392c409a9a5f283b4b5e402c9496db073a2c4040602f5e3d4b5e401d67e43d183a2c40),
(637, NULL, 'service', NULL, NULL, 'way/889084137', 0x00000000010200000002000000956d9681394b5e40fd82ddb06d392c40b631d17b3e4b5e4002f96de3aa392c40),
(638, NULL, 'residential', NULL, NULL, 'way/889085573', 0x0000000001020000000600000052baf42fc94a5e40af8339306f382c40911ed0e3c14a5e4086072868ee382c4014bb6c2ac14a5e40b114c95702392c4014bb6c2ac14a5e40413a86110c392c404f2f42c2c14a5e40637d03931b392c406dfd99e6c24a5e403994467133392c40),
(639, NULL, 'service', NULL, NULL, 'way/889093944', 0x00000000010200000002000000fc4b9c26fd4a5e4029b16b7bbb392c40c63eb786084b5e408095e8d1f9392c40),
(640, NULL, 'unclassified', NULL, NULL, 'way/889093945', 0x00000000010200000006000000a536cc2b324b5e40a1606b5b39382c407ebed29e374b5e4090d728907e382c40da9722af3d4b5e40fbdf5ba2c4382c40c8cd70033e4b5e40cea4f21bcb382c40c8cd70033e4b5e40657fea69d1382c40fe3ff3de3d4b5e40841d1032da382c40),
(641, 'Jose P. Laurel Street', 'residential', NULL, NULL, 'way/891082375', 0x00000000010200000002000000526342cca5415e40548d5e0d506a2d401f99b3e3ab415e402788ba0f406a2d40),
(642, 'Sampaguita Street', 'service', NULL, NULL, 'way/891086546', 0x00000000010200000007000000b403ae2be6415e40e757ce39d3672d406d29d65fe5415e40548ac2d3d0672d407fae6cd5e4415e40b5d2b540cc672d40240c0396dc415e40228d0a9c6c672d4056010869d7415e403938222933672d40a5efda4ad4415e406f7e688b10672d406d3189c4ce415e408ad1cec4cf662d40),
(643, NULL, 'service', NULL, NULL, 'way/891089724', 0x000000000102000000060000000e277a2af1415e40d70231bf89672d4014a232b4f0415e40eb26e77a91672d4020c6b5ebef415e40b82e466e97672d40e3c62de6e7415e406ce6351bd0672d40e9b7af03e7415e40d5480158d3672d40b403ae2be6415e40e757ce39d3672d40),
(644, NULL, 'service', NULL, NULL, 'way/892200970', 0x00000000010200000002000000339875b5cb495e40ec4ca1f31a372c40efc4515ed0495e4024ec8090d1362c40),
(645, NULL, 'service', NULL, NULL, 'way/892200972', 0x000000000102000000070000004cde0033df495e404700378b17372c40486fb88fdc495e408098295206372c40d701c6e9da495e40f5577ecffe362c407f32c687d9495e400f3c6304f9362c40025c3574d8495e401e86fb6df4362c4015127a47d7495e40a9f17794ef362c40efc4515ed0495e4024ec8090d1362c40),
(646, 'West San Francisco Street', 'residential', NULL, NULL, 'way/894168208', 0x00000000010200000003000000a59e05a13c415e404065a1421a6a2d40ffb858ac3c415e4038cd4c7a296a2d401a7b40ea40415e40dc5e775f3a6a2d40),
(647, NULL, 'service', NULL, NULL, 'way/894190613', 0x00000000010200000003000000c3d5011077415e403013a001506c2d40344690ef77415e40ee93a300516c2d407ece93217d415e40159f4ced566c2d40),
(648, NULL, 'service', NULL, NULL, 'way/894190614', 0x0000000001020000000700000068a384aa62415e409dfea2ba6f6b2d404512bd8c62415e40eba463737a6b2d407a843f6862415e403fe08101846b2d40bc2eb25362415e40ba313d61896b2d408016010462415e4051e1630b9c6b2d4087bfcbb161415e40f64ab43fab6b2d40e63dce3461415e40ab1386b7bd6b2d40),
(649, 'Arellano Street', 'residential', NULL, NULL, 'way/894190615', 0x0000000001020000000500000017d11b936a415e402f055a70f56a2d404c8281316c415e40edf5ee8ff76a2d40da988d846c415e40b6f0619bf96a2d40f02774a870415e40c984a977026b2d407fc8b66771415e402e92d15c026b2d40),
(650, 'Upper Garcia Extension', 'residential', NULL, NULL, 'way/894190616', 0x000000000102000000060000002f17f19d98415e40bfe5fbf37e692d40da6be6359b415e405e2d776682692d409d30bced9d415e40e560360186692d404fcfbbb1a0415e403c24c67c8a692d40dba8a9c0a4415e40aadb341191692d4039ea8dffa7415e40363cbd5296692d40),
(651, NULL, 'service', NULL, NULL, 'way/894190618', 0x000000000102000000020000007730629f80415e40ef4806cab7682d40d7135d177e415e40d268177893682d40),
(652, NULL, 'residential', NULL, NULL, 'way/894329673', 0x0000000001020000000200000069c4cc3e8f415e4007639f5b436c2d40d06a37b08b415e403e2075e0416c2d40),
(653, NULL, 'residential', NULL, NULL, 'way/894329674', 0x00000000010200000004000000fe1076e58e415e406a49ec7f256c2d4057e311818f415e40612c1dbd2b6c2d4069c4cc3e8f415e4007639f5b436c2d404c7d0f4d8f415e40e4f159434e6c2d40),
(654, 'Fremont Street', 'residential', NULL, NULL, 'way/894329675', 0x000000000102000000030000003781334289415e405475ea25216c2d40ba1a344f89415e404b71fa1f056c2d40723dc04989415e40801cdebded6b2d40),
(655, NULL, 'residential', NULL, NULL, 'way/894427379', 0x000000000102000000030000008b2194522b415e4043aed4b3206c2d40314c5c7d2b415e40e58fb3fa346c2d4067310cb32b415e40528ce20b496c2d40),
(656, NULL, 'service', NULL, NULL, 'way/894477203', 0x000000000102000000020000002506819543425e40d46b6924f8692d40bdace4be30425e40418f62cad1692d40),
(657, NULL, 'service', NULL, NULL, 'way/894477612', 0x000000000102000000020000002c595f6e41425e40b50b1703356a2d401fb0bcf52b425e4030a182c30b6a2d40),
(658, NULL, 'residential', NULL, NULL, 'way/894547368', 0x000000000102000000020000007957e2a6ab425e40850a0e2f88682d406daf6076aa425e40904fc8cedb682d40),
(659, NULL, 'service', NULL, NULL, 'way/894548120', 0x000000000102000000020000004b5b5ce3b3425e40fa5fae450b682d40c784984baa425e4044087e0a36682d40),
(660, NULL, 'footway', NULL, NULL, 'way/894553357', 0x00000000010200000007000000f3edb83cb1415e40d9b11188d7692d408294336fb0415e402ae0432edd692d4082210615b0415e40219b9abae1692d40a63fa0d8af415e40e3e0d231e7692d400b1fb699af415e4090ff5dfaf2692d4023d74d29af415e4093fe5e0a0f6a2d40d6afcff7ae415e400b027514316a2d40),
(661, NULL, 'residential', NULL, NULL, 'way/894583554', 0x00000000010200000005000000825c3d8276415e4051002082056b2d401131cad875415e403fe65ebb0f6b2d40b88fdc9a74415e40834f73f2226b2d4066f3dd5273415e401a6f2bbd366b2d40e3a430ef71415e40afb6bd384c6b2d40),
(662, NULL, 'residential', NULL, NULL, 'way/894583555', 0x000000000102000000030000007fc8b66771415e402e92d15c026b2d40ba6a9e2372415e40eda2433b026b2d401131cad875415e403fe65ebb0f6b2d40),
(663, NULL, 'service', NULL, NULL, 'way/894584850', 0x0000000001020000000500000043e966da59415e40cd49deef066b2d4044ef9e4d58415e400f812381066b2d40aa5e23ee56415e404a6bc2ac066b2d40bca13a6755415e40bbf2599e076b2d40c481ebe552415e40efb72c150a6b2d40),
(664, NULL, 'service', NULL, NULL, 'way/894590253', 0x00000000010200000002000000dc076a4224425e406dfbc33b656a2d4013dacde737425e407df9ae528b6a2d40),
(665, NULL, 'service', NULL, NULL, 'way/894590254', 0x00000000010200000008000000509ced1b29425e40b0fb33283f6a2d400a979f6527425e40237bce273c6a2d40f8cf89f326425e40419479f53b6a2d40ec0d637726425e4010dc92663d6a2d4052d66f2626425e406272593b406a2d406ad322ec25425e4031e24c5d436a2d40dc076a4224425e406dfbc33b656a2d4024c09fd021425e40dc1ece0d976a2d40),
(666, NULL, 'service', NULL, NULL, 'way/894595994', 0x000000000102000000020000008fed6b135d425e40d70ae42373662d40352905dd5e425e40de567a6d36662d40),
(667, NULL, 'service', NULL, NULL, 'way/894597323', 0x00000000010200000002000000975e51007b425e401ca0ea460e672d40d24554f27b425e400520a45d3b672d40),
(668, NULL, 'service', NULL, NULL, 'way/894864822', 0x000000000102000000020000004c8c65fa25425e4080684183a8662d40a75f7d972d425e40f5edc96889662d40),
(669, NULL, 'service', NULL, NULL, 'way/895664155', 0x000000000102000000020000006857c62bb5415e4093fc2da63e6d2d403a1389f8bd415e40ac956478476d2d40),
(670, NULL, 'service', NULL, NULL, 'way/895664156', 0x00000000010200000002000000ae179ef2c3415e401f53d21e8a6d2d401f9cf463b8415e403d36b863a06d2d40),
(671, NULL, 'service', NULL, NULL, 'way/895664157', 0x00000000010200000006000000f4273b47ae415e40786ae4a9fd6c2d403c1cb85eae415e4070dd83c6026d2d402fb319f1ae415e40b1886187316d2d4011c88047af415e40e56a1aca3f6d2d40234a7b83af415e40e05a37ef496d2d4027fb4223b3415e40bc36c071be6d2d40),
(672, 'Sikatuna Street', 'residential', NULL, NULL, 'way/896456572', 0x00000000010200000002000000e3214212ac415e4020196140e56a2d403b472e49af415e406540aceddc6a2d40),
(673, NULL, 'service', NULL, NULL, 'way/896483848', 0x00000000010200000003000000024bae6271425e40cb01710d22682d40eb11b4136f425e408fec003e2e682d40f8808af46c425e4095568d6f39682d40),
(674, NULL, 'service', NULL, NULL, 'way/897001436', 0x00000000010200000002000000ee748cd074425e409f083df60e6a2d40cf520d5677425e40a3f84212076a2d40),
(675, NULL, 'service', NULL, NULL, 'way/897001437', 0x00000000010200000002000000eee7b92a75425e40e08442041c6a2d40ee748cd074425e409f083df60e6a2d40),
(676, NULL, 'service', NULL, NULL, 'way/897001438', 0x000000000102000000030000007b095fa978425e40c878944a786a2d40d59c178277425e40c0779b374e6a2d40f3cf679b76425e40717731282e6a2d40),
(677, NULL, 'service', NULL, NULL, 'way/897001439', 0x00000000010200000003000000f3171f0b76425e40c514f6fe506a2d408878358a76425e40548d5e0d506a2d40d59c178277425e40c0779b374e6a2d40),
(678, NULL, 'residential', NULL, NULL, 'way/897412195', 0x000000000102000000180000003f81c17f844a5e408ad7ab7e5b362c400923ac7c854a5e4033f735374b362c40623dff87854a5e40619a33ec41362c40c8c0f000854a5e401d1142f630362c40e0788890844a5e4057e9ee3a1b362c40fe91335e844a5e40ddc2047f09362c4075f3435b844a5e40f0445a74fc352c4045e2d4bd844a5e40799bedc0ef352c403240fdc2864a5e404442a55bc0352c4085df9744874a5e4048eaf307b9352c40140dada9874a5e406c98fcaab7352c4067ac472b884a5e40bad91f28b7352c4037c9eab1884a5e400d0055dcb8352c40bfee74e7894a5e40c98855cdbd352c40e2900da48b4a5e4079b4cc7dcd352c40f3f5c65a8d4a5e40a6d65647e9352c403fcf55a98f4a5e401d55f25602362c40fd9474de904a5e40e78c28ed0d362c4086bafe13924a5e40967bdc1214362c40defc2bd0934a5e4089096af816362c40952ded2f964a5e40493ab99514362c40e8813408984a5e40b644d37e10362c408d7516629a4a5e404725d0bb0c362c408c834bc79c4a5e40857afa08fc352c40),
(679, NULL, 'residential', NULL, NULL, 'way/897412196', 0x0000000001020000000300000034c1cb67544a5e40d910d20957362c4025fecd305a4a5e4023c78ca669362c40c49ed1b15e4a5e405114e81379362c40),
(680, NULL, 'service', NULL, NULL, 'way/897444042', 0x0000000001020000000300000037ddb2437c425e409a80badcbb692d40de2120ba7b425e4091d6732db5692d400000000080425e400d0e40b4a0692d40),
(681, NULL, 'service', NULL, NULL, 'way/897525232', 0x00000000010200000002000000bcba192433425e408687d5c4a7692d40c87c40a033425e40db526232b0692d40),
(682, 'Rockville Avenue', 'residential', NULL, NULL, 'way/899751783', 0x000000000102000000020000000b42791f47425e404881aa76f2662d406fd39ffd48425e4004a50d2cec662d40),
(683, NULL, 'service', NULL, NULL, 'way/902549218', 0x00000000010200000006000000217c838a05425e40361c3b4d0b672d40ebf2f79c05425e400809ac7713672d40bc6e5ba505425e4099b3e32b26672d40741eba4505425e408e03af963b672d402dce18e604425e40a3810ea958672d4087753e9704425e40ab0084b46b672d40),
(684, NULL, 'service', NULL, NULL, 'way/902636964', 0x00000000010200000005000000321180c9d7425e400b4e33935e662d403d0feeceda425e4005662a696a662d4054dbf236db425e40c356bf886c662d40fb33cd85db425e40c73bd1bf6e662d40ef5701bedb425e409cb0b3d771662d40),
(685, NULL, 'service', NULL, NULL, 'way/902646943', 0x00000000010200000002000000117b57f3d2415e40d32c75351e692d40828fc18ad3415e40988a8d791d692d40),
(686, 'Gray Parrot Street', 'service', NULL, NULL, 'way/902666139', 0x00000000010200000003000000c5f5398867425e400b3895568d672d409735560765425e40daa7887890672d4063145f4862425e40c630276893672d40),
(687, 'Taurus Street', 'residential', NULL, NULL, 'way/902666140', 0x00000000010200000002000000b7cf2a33a5425e400e6b854435682d40fd21ecca9d425e40f6c2537e08682d40),
(688, 'Ramos Street', 'residential', NULL, NULL, 'way/902666142', 0x0000000001020000000200000095e35f15b9425e40bae875d54d672d40934ac2cfc9425e40b13f3f4283672d40),
(689, NULL, 'service', NULL, NULL, 'way/902678684', 0x00000000010200000002000000807b43867a415e407abcda9b296e2d4037644d767d415e40923534af346e2d40),
(690, 'Bougainvilla Street', 'service', 'yes', NULL, 'way/905228071', 0x0000000001020000000400000087bab486f7415e406a6391cb24672d40b10b5064f7415e403a3b191c25672d403491e398f6415e40ce50dcf126672d409a2e7a5df5415e40bdd17def25672d40),
(691, 'Bougainvilla Street', 'service', 'yes', NULL, 'way/905529267', 0x000000000102000000040000009a2e7a5df5415e40bdd17def25672d405eb46c52f6415e40aeda90da1f672d40a58e441ef7415e40c7c672011e672d40b1dd3d40f7415e40f7eeeab01d672d40),
(692, NULL, 'service', 'yes', NULL, 'way/910643614', 0x0000000001020000000b0000000750429f7e425e40c8e41e5c4b6a2d40ed9fa70183425e401651137d3e6a2d408dc2e4fc83425e40bc0512143f6a2d40ecb078a084425e40599d41e8456a2d40ec23a6fa84425e406ce9d1544f6a2d40e64cc92885425e405055a181586a2d40d457a19284425e4064517d8c5e6a2d40e85bd54881425e403666c867686a2d40775e74c380425e4083cfc595696a2d40b8509e1e80425e40051e73f96a6a2d4065b1039d7f425e405e914e136c6a2d40),
(693, NULL, 'service', 'yes', NULL, 'way/910645067', 0x00000000010200000003000000274ae7687a425e408f2d156580692d403ebac7887a425e408e9da68581692d40f18fad1d7b425e40b3f803d48a692d40),
(694, NULL, 'service', NULL, NULL, 'way/910645068', 0x000000000102000000020000005dd60e9079425e40acdb453de9692d4013bc7c467d425e40ab9e82b2df692d40),
(695, 'Goodwill Avenue', 'residential', NULL, NULL, 'way/910684114', 0x000000000102000000040000001f64593071415e40c680368309692d403f30ecd56c415e40eff66a91fe682d40d083166d69415e40053ef5fef5682d405981c6f168415e4012d841caf4682d40),
(696, 'Goodwill Avenue', 'residential', 'yes', NULL, 'way/910684115', 0x00000000010200000004000000be6bd0975e415e40485b4bb7db682d405c316d4958415e40b4983336cf682d400d51853f43415e40766ad37da5682d40449b2d6a41415e40483a5edca1682d40),
(697, 'Barangay San Bartolome Road', 'unclassified', NULL, NULL, 'way/910781506', 0x0000000001020000001700000069a109b9f74a5e40b0cb4b59e1392c400360973cf94a5e4083b8bc83e9392c40b52f455efb4a5e40412ecc9df4392c40fba7c06efd4a5e40ef6c3425fe392c407176c652ff4a5e40806a172e063a2c40992e1fa4024b5e40505f854a123a2c402d584f52054b5e40d98a47f3113a2c40974a896e074b5e4072f8a413093a2c40c63eb786084b5e408095e8d1f9392c409cd3765d094b5e406e693524ee392c40b340bb430a4b5e40e2506452e8392c40ee9aeb8f0b4b5e40aefb22fce6392c4059a7caf70c4b5e401c430070ec392c4015ee4bec104b5e4003740415fa392c400e0e9b6d134b5e40d6389b8e003a2c40c6e5d3be144b5e403421f7be023a2c404215ede0164b5e40c6f6ff16093a2c400b862980184b5e40096b0833123a2c40cfdd0951194b5e402a013109173a2c401cebe2361a4b5e40a73ffb91223a2c407b32ffe81b4b5e402f68c647303a2c408c248b451d4b5e40adc66d8f393a2c404f5f2a911f4b5e406517b1f4463a2c40),
(698, NULL, 'service', NULL, NULL, 'way/910904246', 0x000000000102000000020000002c595f6e41425e40b50b1703356a2d40cd2e29884b425e40ee8a2a0d466a2d40),
(699, NULL, 'service', NULL, NULL, 'way/913889059', 0x00000000010200000005000000d2cec4cfda495e4093fa57fbe0352c403f4fa84cd6495e405f07ce1951362c40fa241c1fd2495e408a3265f1ac362c409b4d918dd1495e40cbf6216fb9362c40efc4515ed0495e4024ec8090d1362c40),
(700, NULL, 'service', NULL, NULL, 'way/921228113', 0x00000000010200000002000000b6f0619b79425e40ddf6f35c956a2d40159ada087a425e40053f60d4a46a2d40),
(701, NULL, 'service', NULL, NULL, 'way/922476625', 0x0000000001020000001c0000000508d5bc99415e401b0c1a9f6e6d2d400684d6c397415e40aca8667b996d2d401e25654197415e407f4523449e6d2d40e3827d8596415e4066118aada06d2d408421bc8795415e40e3eab6faa06d2d40fcfb315294415e4014a39d899f6d2d4028dd4c3b6b415e40a2b2614d656d2d40ca1f67f569415e4003232f6b626d2d40b8a008f368415e409a50d20d5e6d2d40faa93b6068415e4081b79b3b556d2d400ca2ff2f68415e40bc3c9d2b4a6d2d400c885ae468415e4014b7651b136d2d406b03c12d69415e405f5331df0b6d2d4035327ed069415e40df8cf568056d2d409aaf37d66a415e401722f13c026d2d40db25602a6c415e40b114c957026d2d40cc51369b7d415e40a4dc22d51c6d2d402569ed6c7e415e40269b61591f6d2d40959460167f415e407dee5fb4226d2d40d002fe3a81415e40f7cc9200356d2d40c4995fcd81415e40246d99c2396d2d40f331699d82415e40220505943c6d2d4081ef91288f415e404400cba54c6d2d40759dfccc8f415e40a97d84ab4d6d2d40d446753a90415e40bab42b3e4f6d2d406346787b90415e4088dc67f0526d2d4063748a9f90415e40c1864c9e576d2d40e04db7ec90415e4088b1964c5f6d2d40),
(702, 'Saint Joseph Street', 'residential', NULL, NULL, 'way/924025504', 0x0000000001020000000d000000b00e362b91415e40b09c73a6bf6d2d400c52955b7f415e407b551d28a66d2d40544c4ae67d415e40f90670c4a46d2d40c3a453b277415e4079f87cde9e6d2d40f9d4569176415e404940964fa06d2d401179814875415e4029e73004a56d2d4083c1357774415e406dc3cd4eab6d2d401ee8572973415e40a15dcf21ba6d2d4072bb3c4272415e4089f667f5c46d2d40e4ece75e71415e403e5a9c31cc6d2d40de8e705a70415e40ade93015d16d2d40d32b0a606f415e40992a1895d46d2d40bcd5ce8b6e415e4021ee450fd76d2d40),
(703, NULL, 'service', 'yes', NULL, 'way/926743233', 0x0000000001020000000300000065b1039d7f425e405e914e136c6a2d40a2a1da3b7e425e40334ee89a6e6a2d4073dbbe477d425e40c663ab70706a2d40),
(704, NULL, 'service', 'yes', NULL, 'way/926743234', 0x00000000010200000002000000f0726c987c425e40db08d517536a2d400750429f7e425e40c8e41e5c4b6a2d40),
(705, NULL, 'service', NULL, NULL, 'way/926743236', 0x000000000102000000020000000750429f7e425e40c8e41e5c4b6a2d4065b1039d7f425e405e914e136c6a2d40),
(706, NULL, 'service', NULL, NULL, 'way/926743238', 0x0000000001020000000300000045f3001679425e4053dc0253176a2d400a51195a78425e40236cd333186a2d40eee7b92a75425e40e08442041c6a2d40),
(707, NULL, 'service', 'yes', NULL, 'way/926743239', 0x000000000102000000060000008b37328f7c425e40bcc568c29b6a2d409eabf7657a425e40e0d00083496a2d408627aa6d79425e403550cf71246a2d4045f3001679425e4053dc0253176a2d407594de9277425e4084d89942e7692d40cf97288c77425e40c8b02f7ebf692d40),
(708, NULL, 'service', 'no', NULL, 'way/926751513', 0x0000000001020000000200000089528c3d45425e405e6cb5e276672d405bf1683e42425e407ca2467c82672d40),
(709, NULL, 'service', 'yes', NULL, 'way/926751514', 0x00000000010200000002000000e949f48d43425e404cdb64f95f672d404ca4349b47425e4070777bb548672d40),
(710, NULL, 'service', 'yes', NULL, 'way/926751515', 0x000000000102000000030000005bf1683e42425e407ca2467c82672d40682f91c140425e4009a128756e672d40e949f48d43425e404cdb64f95f672d40),
(711, NULL, 'service', NULL, NULL, 'way/926751516', 0x0000000001020000000200000089528c3d45425e405e6cb5e276672d40e949f48d43425e404cdb64f95f672d40),
(712, NULL, 'service', 'yes', NULL, 'way/926751517', 0x00000000010200000002000000277dc62a4a425e40158e209562672d4089528c3d45425e405e6cb5e276672d40),
(713, NULL, 'service', 'yes', NULL, 'way/926757517', 0x00000000010200000006000000f42d18013a425e40600fdc37ad662d40fb1e9a1e39425e40e81ac121af662d405481a49938425e4094d4aeaeaf662d4066d828eb37425e401286014bae662d4090e4a89237425e40fc219111ab662d40f684db9035425e40284b08b18e662d40),
(714, NULL, 'service', NULL, NULL, 'way/926838035', 0x00000000010200000002000000002bd1a373425e406de4ba29e5692d40ac0c99e175425e401be95619d7692d40),
(715, NULL, 'service', NULL, NULL, 'way/926838036', 0x00000000010200000002000000d6c4a7a55e425e408a63134f2c6a2d407c629d2a5f425e40da6674513e6a2d40),
(716, 'Opal Street', 'residential', NULL, NULL, 'way/930557426', 0x0000000001020000000700000090aff3250a425e407b53ecc3d5682d408bfb8f4c07425e40a622ba0ca4682d40e5a2b5fd06425e40f12e17f19d682d4020031ebd06425e40a6bd1cd198682d40515fe00305425e40ac6b596375682d40c276e6d404425e408518f90670682d40f2e379ba04425e4023dbf97e6a682d40),
(717, NULL, 'service', NULL, NULL, 'way/930562130', 0x000000000102000000020000000bc96e0b3b425e40e949f48d43682d40f26668974a425e40fd50c47d3f682d40),
(718, NULL, 'service', 'yes', NULL, 'way/930948709', 0x00000000010200000005000000666f84a07e425e406f795160a66a2d402b2c5d667d425e40af004b53a96a2d40675eb3017d425e403e59d6a2aa6a2d40969d34c37c425e4019f3846fab6a2d4057a30d7679425e403e062b4eb56a2d40),
(719, NULL, 'service', 'no', NULL, 'way/930948710', 0x00000000010200000002000000aabb0dc578425e408977256eba6a2d4057a30d7679425e403e062b4eb56a2d40),
(720, NULL, 'service', NULL, NULL, 'way/931023426', 0x000000000102000000120000002fa2ed983a425e409721e92ee4682d405877876f3c425e40dd1d6338e8682d40103b53e83c425e40233aba00ea682d40b7c13f5b3d425e40335184d4ed682d408d9eb6a13d425e40f5262b2bf2682d40e6cc76853e425e40abe408be0e692d4021b715b13e425e40f72d292d12692d40c826f9113f425e4078ec67b114692d407ae5d5943f425e404834812216692d40b054bc3640425e40543e5f0e16692d4093dd712f55425e4017957950f5682d40800d881057425e4071d696f03a692d40c3eb9f4c48425e401ea2766451692d40f3e8a11147425e409aeb34d252692d407d00f7e145425e40c37e4fac53692d4001b7387444425e40763d2c2f54692d406d14a3f842425e40458545a055692d40be73deb53a425e40b0b4424761692d40),
(721, NULL, 'path', NULL, NULL, 'way/931032936', 0x00000000010200000002000000dad605723f425e40100874266d6a2d40509ced1b29425e40b0fb33283f6a2d40),
(722, NULL, 'service', NULL, NULL, 'way/931309623', 0x0000000001020000000200000098e2056c62425e40f689f2bb9f692d40d5ec815660425e4098929b9779692d40),
(723, NULL, 'service', NULL, NULL, 'way/931325947', 0x00000000010200000002000000b982b751ae415e40198d21a57e6b2d40335ea91db4415e403059260d7f6b2d40),
(724, NULL, 'service', NULL, NULL, 'way/931325948', 0x00000000010200000003000000c4fc265e2f425e40e02f664b56692d40fd97b55e1d425e4024d236fe44692d401a97bbe01d425e40409c2c5a25692d40),
(725, NULL, 'service', NULL, NULL, 'way/932297046', 0x00000000010200000002000000b2518ce20b425e40bf45274bad6b2d400c10bba50b425e40271186a6916b2d40),
(726, NULL, 'service', NULL, NULL, 'way/933222970', 0x00000000010200000002000000f9ad8cfc30425e40f1bd1afbed662d4052c8df0731425e4022f8849103672d40),
(727, NULL, 'service', NULL, NULL, 'way/933222971', 0x00000000010200000002000000e770adf630425e4007bdedf8e5662d40f9ad8cfc30425e40f1bd1afbed662d40),
(728, NULL, 'service', NULL, NULL, 'way/933222972', 0x0000000001020000000600000052c8df0731425e4022f8849103672d40e1e1879430425e40063c7a0d0b672d400cdd369d2e425e404700378b17672d40b33b495f2d425e4088cfe7ed19672d40a2d68fa82b425e40d438e51b1b672d4062d9cc2129425e404ce548c219672d40),
(729, NULL, 'service', NULL, NULL, 'way/933222973', 0x0000000001020000000200000030ef16ed16425e408ebdcdd199662d40173147ea18425e406d9e341eb6662d40),
(730, NULL, 'service', NULL, NULL, 'way/934187957', 0x0000000001020000000400000011c88047af415e40e56a1aca3f6d2d4035b2d073b0415e40ffdb76eb466d2d409f4b8281b1415e40c0b91a344f6d2d40fdeec27bb3415e401cc75922616d2d40),
(731, NULL, 'service', NULL, NULL, 'way/934195721', 0x000000000102000000050000004b8c0a41b3415e40ead6c633c36d2d407868b345ad415e407ee19524cf6d2d405ac86d45ac415e40fb027ae1ce6d2d40319177b3ab415e402189a8d3cb6d2d405553ed2eab415e40b9718bf9b96d2d40),
(732, NULL, 'service', NULL, NULL, 'way/934277091', 0x00000000010200000002000000cf520d5677425e40a3f84212076a2d40ac0c99e175425e401be95619d7692d40),
(733, NULL, 'service', 'yes', NULL, 'way/934285087', 0x00000000010200000004000000f8ea991455425e40be45cc913a6a2d40574ff74b55425e40a6e9584a3b6a2d40f1941f0258425e40e413b2f3366a2d40cc28965b5a425e4021f6532d336a2d40),
(734, NULL, 'service', 'yes', NULL, 'way/934285088', 0x00000000010200000002000000d95bcaf962425e4052d90b60256a2d4099a0866f61425e40f1475167ee692d40),
(735, NULL, 'service', 'yes', NULL, 'way/934285089', 0x0000000001020000000600000087a00f3b78425e402b114d45cf6a2d40f3e3d47377425e4085ecbc8dcd6a2d409b7631cd74425e40ad5ffaa8d06a2d40e9a683ab72425e4099a0e128d46a2d407fb4498f70425e40b651f8c7d66a2d409ebfbff76d425e406c1dc132db6a2d40),
(736, NULL, 'service', 'yes', NULL, 'way/934285090', 0x000000000102000000020000005d6e30d461425e40e0c03f00046b2d40fd1d407562425e4045f64196056b2d40),
(737, NULL, 'service', NULL, NULL, 'way/934285091', 0x00000000010200000002000000c93ec8b260425e409370218fe06a2d405d6e30d461425e40e0c03f00046b2d40),
(738, NULL, 'service', NULL, NULL, 'way/934286609', 0x000000000102000000020000009ebfbff76d425e406c1dc132db6a2d40afaeaf1a70425e4021246651336b2d40),
(739, NULL, 'service', NULL, NULL, 'way/934286610', 0x00000000010200000002000000d7602bb267425e407a9ff4cf1d6a2d40d7edfd5767425e40fe1076e50e6a2d40),
(740, NULL, 'service', NULL, NULL, 'way/934286611', 0x0000000001020000000200000060a692a666425e4025c9737d1f6a2d40efd6434566425e40a62d09ab0c6a2d40),
(741, NULL, 'service', NULL, NULL, 'way/934286612', 0x0000000001020000000200000073cf04d465425e40b421ffcc206a2d406108ef6165425e402497a4d70b6a2d40),
(742, NULL, 'service', NULL, NULL, 'way/934286613', 0x00000000010200000003000000b5dbd37a64425e405f398c930c6a2d40d322916c64425e40bc9179e40f6a2d40a33f34f364425e40dd6c6237226a2d40),
(743, NULL, 'service', NULL, NULL, 'way/934286614', 0x0000000001020000000e000000d95bcaf962425e4052d90b60256a2d40a33f34f364425e40dd6c6237226a2d4073cf04d465425e40b421ffcc206a2d4060a692a666425e4025c9737d1f6a2d40d7602bb267425e407a9ff4cf1d6a2d40bfedae5868425e40b01413e51c6a2d40ad23fdac68425e404065a1421a6a2d4089ee59d768425e404eaf39ac156a2d40dca799a468425e400fb8ae98116a2d40d7edfd5767425e40fe1076e50e6a2d40efd6434566425e40a62d09ab0c6a2d406108ef6165425e402497a4d70b6a2d40a31122cf64425e40cbdb114e0b6a2d40b5dbd37a64425e405f398c930c6a2d40),
(744, NULL, 'service', NULL, NULL, 'way/934505862', 0x000000000102000000020000003c003d6851425e408badfb22fc6a2d40ee48505752425e40887c3c99246b2d40),
(745, NULL, 'service', NULL, NULL, 'way/934505863', 0x00000000010200000002000000aec4f29d4e425e404274ad62966a2d409506239b50425e405666a5a4e26a2d40),
(746, NULL, 'service', NULL, NULL, 'way/934505864', 0x0000000001020000000a000000b8a51f1e53425e4023b3c414f66a2d403c003d6851425e408badfb22fc6a2d40a3daf1704c425e40e1e01cbf016b2d400b28d4d347425e40db937659026b2d40e297553346425e404ae93ea5ef6a2d4091a8065042425e40491bfd1eab6a2d40e4ee18c341425e4081f8af62a76a2d40b5560ff340425e40450e1137a76a2d40b6e0a01834425e403ed065c5cb6a2d40168d107926425e40997917940e6b2d40),
(747, 'Atlas Road', 'tertiary', 'no', NULL, 'way/938634914', 0x00000000010200000012000000e8fb04abc5415e4024873e0e396c2d405fe4afdac6415e402ce9cd4d406c2d40f3583332c8415e401dc70f95466c2d403972eec0ca415e409620c8e64f6c2d403eb32440cd415e4008759142596c2d409b502dc7d0415e40d18cea19676c2d40e25817b7d1415e40590861246a6c2d40a07df66dd2415e40b73874c46b6c2d40e757ce39d3415e4022bb1cc06c6c2d40285bc933d4415e40277854466d6c2d406387e75bd5415e40277854466d6c2d4003931b45d6415e407f130a11706c2d40a4fa7376d7415e40e1c09ab9766c2d407058bf3edf415e40f480c355af6c2d4001cf0715e6415e4098f90e7ee26c2d40b933130ce7415e408e4cd1dbe96c2d405a3f47f5e7415e40d7c5c8edf26c2d40a7abe05ce8415e402e895869f76c2d40),
(748, NULL, 'footway', NULL, NULL, 'way/949313980', 0x000000000102000000020000005a643bdf4f425e40764aac318d672d40197849f74e425e40fca5457d92672d40),
(749, NULL, 'footway', NULL, NULL, 'way/949313981', 0x00000000010200000002000000bad16cc34d425e409ec8dd3186672d407e4056a64e425e40e28794b080672d40),
(750, NULL, 'footway', NULL, NULL, 'way/949313982', 0x00000000010200000002000000aef5a0fb4d425e403bc5aa4198672d40197849f74e425e40fca5457d92672d40),
(751, NULL, 'footway', NULL, NULL, 'way/949313983', 0x00000000010200000002000000bad16cc34d425e409ec8dd3186672d40504fc4c74c425e4089e9e7f28b672d40),
(752, NULL, 'steps', NULL, NULL, 'way/949313984', 0x00000000010200000002000000504fc4c74c425e4089e9e7f28b672d40146289624d425e4032d3ac2292672d40),
(753, NULL, 'steps', NULL, NULL, 'way/949313985', 0x000000000102000000020000007e4056a64e425e40e28794b080672d40c0d023464f425e406d58ae1287672d40),
(754, NULL, 'service', NULL, NULL, 'way/962107436', 0x00000000010200000003000000ab75e2723c525e405bc6979a4e0c2c405330197d3b525e40a77455455d0c2c40716369963a525e408ea559ea6a0c2c40),
(755, NULL, 'residential', NULL, NULL, 'way/962630363', 0x000000000102000000060000001a355f259f525e40dabffc5fbf092c40e7673403a6525e40b526cc6a70092c40d59d8257a6525e4065d0bf1369092c4075954968a6525e401b37eb4262092c40f2b62d25a6525e40f573f9c55b092c4023b42feaa4525e403f6370de49092c40),
(756, 'Katipunan Avenue', 'secondary', NULL, NULL, 'way/963839125', 0x00000000010200000008000000da3c693c6c415e401ebc1bb050682d4069c306b06d415e40014cbe7e2d682d401b3dc8fc6d415e40a5ebd33b26682d40ea7ea9fa70415e4046a5c7a5e0672d4019703bd972415e40d8de5d1db6672d409549682673415e40ca77dfe7ae672d4089e0c9b873415e40ac94f9a298672d40a12298b473415e406b31d35169672d40),
(757, 'Katipunan Avenue', 'secondary', NULL, NULL, 'way/963839126', 0x0000000001020000000800000076e7e4a05f415e4000492245ae692d40db087a5e60415e40d0ffbcba74692d4010bd7b3661415e408367e7d951692d4008d7924465415e40bfb10c16f3682d40c6713b8f65415e4075183845ec682d4013f5dd0866415e4010a67224e1682d406ab5d14a6b415e408423edeb65682d40da3c693c6c415e401ebc1bb050682d40),
(758, 'Helpful Street', 'residential', NULL, NULL, 'way/1008024763', 0x0000000001020000000500000076cafed453415e40bdf7dcae3c692d40c2418c214a415e40389f3a5629692d400a815ce248415e40911216702a692d40a58dd94848415e40abf303b232692d40891e42a646415e40c25087156e692d40),
(759, NULL, 'service', NULL, NULL, 'way/1010375834', 0x000000000102000000020000005382b4b574525e402453f4763a0e2c40a2e991ab7d525e4028999cda190e2c40),
(760, NULL, 'service', NULL, NULL, 'way/1022471604', 0x00000000010200000002000000eee7b92a75425e40e08442041c6a2d4030f1ec9774425e40ce2dbeb21c6a2d40),
(761, NULL, 'service', NULL, NULL, 'way/1022471605', 0x00000000010200000003000000ee748cd074425e409f083df60e6a2d40002bd1a373425e406de4ba29e5692d40dd54ee4f73425e40b4bb5175d9692d40),
(762, 'B. Evangelista Drive', 'residential', NULL, NULL, 'way/1029310000', 0x0000000001020000000b000000281fcc376c425e40146289624d682d40f2fadd8577425e4083609f4a17682d408bb0975c7b425e40158c4aea04682d40246651337f425e40fbb5508df2672d40b1b508d682425e40a5654925e1672d4080fa850d85425e4045b0bb8ad6672d403f1f65c485425e40b2028de3d1672d40c1429c3d86425e402cefaa07cc672d40971f138486425e40ad286f91c5672d40e5ea6c6d86425e409f515f3bbd672d4038a4ac3a86425e4028d0cc38b2672d40),
(763, NULL, 'service', NULL, NULL, 'way/1038710112', 0x0000000001020000000200000049d74cbed9495e40c556d0b4c4362c4015127a47d7495e40a9f17794ef362c40),
(764, NULL, 'service', NULL, NULL, 'way/1038710113', 0x00000000010200000007000000fa241c1fd2495e408a3265f1ac362c4032b55b81d7495e40da35c6f3be362c4049d74cbed9495e40c556d0b4c4362c40723c5574da495e40e232b8f7ba362c4078279f1edb495e40123356f6b8362c40e3a9471adc495e40b9e7548db9362c4009281e61e2495e40e1777874c8362c40),
(765, NULL, 'service', NULL, NULL, 'way/1058687146', 0x00000000010200000002000000843d377ef2425e40e909f0822d672d40fbb5508df2425e4033164d6727672d40),
(766, 'Assisi Street', 'tertiary', NULL, NULL, 'way/1058687147', 0x0000000001020000000500000017b5a09c0d435e40c7f65ad07b672d409edfe64306435e40bcc4a2337a672d405daed92505435e40f7f6f8ce79672d4045ce67e503435e40bc54111379672d408145d9b603435e40216239f878672d40),
(767, NULL, 'service', NULL, NULL, 'way/1058687148', 0x000000000102000000020000009f292ad1c8425e4018c7ed3c96672d407470fac4cb425e40c6bd9e54a0672d40),
(768, NULL, 'service', NULL, NULL, 'way/1058687149', 0x0000000001020000000200000072aebc3fb9425e40189238d0e8672d40a7d887abb9425e4044f57b07e4672d40),
(769, 'Quirino Highway', 'primary', NULL, 'Manila-Del Monte-Garay Road', 'way/1058687152', 0x00000000010200000002000000556820964d425e4057ac866984672d40c1070a174d425e40cb0347b87f672d40),
(770, 'Quirino Highway', 'primary', 'no', 'Manila-Del Monte-Garay Road', 'way/1058687153', 0x000000000102000000040000005cf45f3134425e40ecf7c43a55662d40629a8ea534425e403c4ed1915c662d407a4f8afb34425e40ecccf39661662d406d6d86c036425e4097a0d0fc7b662d40),
(771, NULL, 'residential', NULL, NULL, 'way/1058687154', 0x00000000010200000003000000c1070a174d425e40cb0347b87f672d40a9c29fe14d425e40c331265877672d40b757303b55425e402e2350583d672d40),
(772, 'Rockville Avenue', 'residential', 'yes', NULL, 'way/1058687156', 0x00000000010200000002000000cdafe60041425e40b57dd98706672d407e09cb8e43425e40f002db77fb662d40),
(773, 'Rockville Avenue', 'residential', 'yes', NULL, 'way/1058687157', 0x000000000102000000020000001398f33144425e407039a80e03672d4079aeefc341425e40ed7772970e672d40),
(774, 'Saint Michael Street', 'residential', NULL, NULL, 'way/1058687771', 0x000000000102000000030000008db80034ca425e406fc61ffb0f672d4043424aa2cd425e405db34b0ae2662d4073501d06ce425e40cb4dd4d2dc662d40),
(775, NULL, 'residential', 'no', NULL, 'way/1058951338', 0x00000000010200000002000000ead0e97937425e409818cbf44b682d40fa04f5d239425e408c56a4784b682d40),
(776, NULL, 'footway', NULL, NULL, 'way/1058952940', 0x00000000010200000002000000146289624d425e4032d3ac2292672d40fc4dcd8a4d425e406848cb3791672d40),
(777, 'Senading Street', 'tertiary', NULL, NULL, 'way/1059031390', 0x000000000102000000040000003fa7c585a8425e409b046f48a36a2d40c229bd80a8425e40f02197ee646a2d400fc70446a8425e402d150ac7e2692d40f17f4754a8425e40c07d78f1d9692d40),
(778, NULL, 'residential', NULL, NULL, 'way/1059031394', 0x00000000010200000002000000633ec516a7425e40c7c90e3b9d692d40eaa2320faa425e4035f10ef0a4692d40),
(779, NULL, 'service', NULL, NULL, 'way/1059032109', 0x000000000102000000020000007a185a9d9c425e4021a68e9fd7692d404f6dbaaf94425e401ba19fa9d7692d40),
(780, 'Kappa Street', 'residential', NULL, NULL, 'way/1059058001', 0x000000000102000000020000006709d74837425e40410466cfaf672d40e35295b638425e40dcf63deaaf672d40),
(781, 'Bougainvilla Street', 'service', NULL, NULL, 'way/1059058002', 0x00000000010200000002000000038ea960f9415e40987620a11c672d40c741ae79fa415e40404bfcf61a672d40),
(782, 'Diamond Avenue', 'tertiary', 'no', NULL, 'way/1059058003', 0x00000000010200000008000000e60c20d761425e40447122556f682d40d6ad9e935e425e40c7b4dbd37a682d40e3337e865c425e409ac129bd80682d40962941da5a425e400951bea085682d4074bbf2b457425e402fccf8ad8c682d400c79043752425e402bdcf29194682d40ed365e703c425e40e55e059db5682d40b840dd9b3a425e4025e6fe8fb8682d40),
(783, NULL, 'service', NULL, NULL, 'way/1059058005', 0x00000000010200000002000000c091e5c9da415e40e4fd13b7656b2d406c4bd356db415e40ad6818e3686b2d40),
(784, NULL, 'service', NULL, NULL, 'way/1059649327', 0x000000000102000000020000001661d4ff83415e403d1c6ed1136c2d40c8ac832884415e40b3ccc75ae86b2d40),
(785, 'Goodwill Avenue', 'residential', NULL, NULL, 'way/1059667130', 0x000000000102000000020000005981c6f168415e4012d841caf4682d40c6713b8f65415e4075183845ec682d40),
(786, 'Goodwill Avenue', 'residential', NULL, NULL, 'way/1059669917', 0x00000000010200000002000000c6713b8f65415e4075183845ec682d40be6bd0975e415e40485b4bb7db682d40),
(787, 'Santa Cruz Street', 'residential', NULL, NULL, 'way/1059932828', 0x000000000102000000040000000583103576415e408b3acec87b6c2d400be4237376415e4099846632776c2d40c3d5011077415e403013a001506c2d4004d9fc0978415e408c35b79d116c2d40),
(788, 'Saint Peter Street', 'tertiary', NULL, NULL, 'way/1074465229', 0x00000000010200000002000000e3303d06d0425e4007e9ceb815672d404df2c8c4d2425e4050a6762bf0662d40),
(789, NULL, 'service', NULL, NULL, 'way/1087400027', 0x000000000102000000020000002fb319f1ae415e40b1886187316d2d402d81ef91a8415e4010ae80423d6d2d40),
(790, NULL, 'service', NULL, NULL, 'way/1087439166', 0x00000000010200000006000000072fb07d37425e40298128f3ea672d401a2a108736425e40e7919ad1ea672d4038013c5835425e40351b75bee9672d4080cddebe33425e40ef46d565e7672d40dabf571932425e40d972d30be3672d40a27433ed2c425e40d1aba690d0672d40),
(791, NULL, 'service', NULL, NULL, 'way/1088701883', 0x00000000010200000002000000cbd2f31373425e40cccfb29366682d4021e9d32a7a425e404e7ff62345682d40),
(792, NULL, 'service', NULL, NULL, 'way/1088701884', 0x00000000010200000006000000838d469968425e40e54f0aa991682d40572767286e425e401d835f3475682d405c9ce73e6f425e40c02a72e371682d40fc1a498270425e40098783296f682d40ea36f28a71425e40e0cb8e9e6c682d40cbd2f31373425e40cccfb29366682d40),
(793, NULL, 'service', NULL, NULL, 'way/1098062425', 0x000000000102000000020000000cb89d6c39415e40c4978922a46a2d406eade5843f415e40144438c1926a2d40),
(794, NULL, 'residential', 'yes', NULL, 'way/1098328402', 0x00000000010200000008000000d2e3f736fd415e405706d506276a2d40256c89a6fd415e4037f5262b2b6a2d40138bcee8fd415e40bca074d8336a2d4060843af6fd415e407c3661b13c6a2d409cfbabc7fd415e4071f9b42f456a2d409095a993fd415e40b7f52e39496a2d40f041be3afd415e40b58d9a0a4c6a2d40254113bcfc415e40379490fe4d6a2d40),
(795, NULL, 'service', NULL, NULL, 'way/1098330693', 0x000000000102000000020000000fd65af33e425e40b87deab35e672d40535337bc45425e40fc5580ef36672d40),
(796, NULL, 'residential', 'no', NULL, 'way/1098330694', 0x00000000010200000003000000eb63f49235425e405ce674594c682d40ccbadae536425e4007d3307c44682d401f717e7937425e4019e2fd5d44682d40),
(797, NULL, 'residential', NULL, NULL, 'way/1098474771', 0x0000000001020000000200000095fa682739415e405319106b3b6b2d4097d52ab036415e40c8bb7e1c286b2d40),
(798, NULL, 'service', NULL, NULL, 'way/1098474773', 0x00000000010200000003000000187d602239415e403c9fa63bf46a2d40c78a750536415e40d3de3bc5056b2d40bd642d4f31415e40350a4966f56a2d40),
(799, NULL, 'service', NULL, NULL, 'way/1098694100', 0x000000000102000000080000009ffc828277415e4095cb9074176a2d4017c38b7475415e4044ec0214d9692d405396218e75415e40a4cc6152d7692d400b2cdbe275415e40ec504d49d6692d4028113c1977415e409f9f98abd5692d401ca89dab77415e405e8830d9d3692d40c32e8a1e78415e4060387c77d0692d4034e7cf6d78415e40a31f0da7cc692d40),
(800, 'Lapu-lapu Street', 'residential', NULL, NULL, 'way/1098694106', 0x00000000010200000005000000775f3a52a2415e4059cfff61016a2d404d0b033ba3415e404d559055006a2d4029eacc3da4415e40d033ac98006a2d40763cc159a5415e40649126de016a2d40016663caac415e4081ef91280f6a2d40),
(801, 'Magsaysay Avenue', 'tertiary', NULL, NULL, 'way/1098694107', 0x000000000102000000090000003b037ee85d415e40e8b00cbb396a2d403b8a181b5f415e40f42a7cc73a6a2d4092c3712a63415e402d1d18e53e6a2d40a8e2c62d66415e401a5eff64426a2d40b95bedbc68415e40e2804c21466a2d40ed93ed8d6b415e40684c778d4c6a2d40404a91216c415e40b5b574bb4d6a2d407e213f7672415e4012e390685d6a2d405dbf057e79415e40b939f0c5726a2d40),
(802, NULL, 'residential', NULL, NULL, 'way/1098697508', 0x0000000001020000000200000074886eac7a415e40471d1d57236b2d401131cad875415e403fe65ebb0f6b2d40),
(803, NULL, 'residential', NULL, NULL, 'way/1098697509', 0x000000000102000000030000003a79910978415e407a19c5724b6b2d4033294f6a79415e4097900f7a366b2d4074886eac7a415e40471d1d57236b2d40),
(804, NULL, 'residential', NULL, NULL, 'way/1098697510', 0x00000000010200000002000000b88fdc9a74415e40834f73f2226b2d4033294f6a79415e4097900f7a366b2d40),
(805, NULL, 'service', NULL, NULL, 'way/1098697511', 0x00000000010200000002000000d141977068415e40914d4dddf06a2d4017d11b936a415e402f055a70f56a2d40),
(806, 'Santa Maria Street', 'residential', NULL, NULL, 'way/1098697512', 0x00000000010200000002000000f05d39315a415e40de40dc30656b2d40f75d6cb562415e40f3f400cc6b6b2d40),
(807, NULL, 'service', NULL, NULL, 'way/1098698271', 0x000000000102000000060000009256218a6e415e40e77e3d15266a2d40220038f66c415e40b9de3653216a2d404bf5ae8b6c415e403f45c4831c6a2d40d4939e8e6c415e40e811a3e7166a2d40f2d7bf466d415e405407d4f60a6a2d40987219926e415e402eb76a8df7692d40),
(808, NULL, 'footway', NULL, NULL, 'way/1098698272', 0x00000000010200000004000000de8bd42071415e409985d107266a2d40ea984e4670415e40b56cad2f126a2d40b5125f926f415e402db4739a056a2d40987219926e415e402eb76a8df7692d40),
(809, NULL, 'service', NULL, NULL, 'way/1098698273', 0x00000000010200000002000000e1ffd8356b415e40081f4ab4e4692d40e5828eb16e415e4013510251e6692d40),
(810, NULL, 'service', NULL, NULL, 'way/1098701201', 0x000000000102000000020000001659219b9a415e40f20c75b39a692d40da6be6359b415e405e2d776682692d40),
(811, NULL, 'service', NULL, NULL, 'way/1098701202', 0x000000000102000000020000003dac81f79f415e402252d32ea6692d404fcfbbb1a0415e403c24c67c8a692d40),
(812, NULL, 'service', NULL, NULL, 'way/1098701203', 0x000000000102000000020000007cb779e3a4415e406b7418dd8b692d409f14f769a6415e40d9edb3ca4c692d40),
(813, NULL, 'service', NULL, NULL, 'way/1098701204', 0x00000000010200000002000000dba8a9c0a4415e40aadb341191692d407cb779e3a4415e406b7418dd8b692d40),
(814, NULL, 'footway', NULL, NULL, 'way/1098702491', 0x00000000010200000006000000e26366553a425e406fd003c4c9662d405481a49938425e4094d4aeaeaf662d4043bd2a6137425e408b355ce49e662d40087a032736425e40e27668588c662d40fdd41d3034425e400e58288870662d40b614ebaf32425e40c00413245b662d40),
(815, NULL, 'footway', NULL, NULL, 'way/1098702493', 0x00000000010200000004000000b47570b037425e40c0102851e5662d408a3e7a1e37425e4095b0db0cdc662d40e472727536425e405919e835d1662d4026ad534035425e40bbb486f7c1662d40),
(816, 'North Point Street', 'residential', 'yes', NULL, 'way/1098703453', 0x00000000010200000004000000c5573b8af3415e40a5cd829a6b6a2d406c26df6cf3415e403b4bda9e6a6a2d403c180c09f3415e409c035f2c676a2d40a20e2bdcf2415e4085c7c8a3656a2d40),
(817, NULL, 'service', NULL, NULL, 'way/1098703459', 0x00000000010200000002000000d236fe44e5415e402e104e55eb6a2d404496bb85e4415e408a5352cce66a2d40),
(818, NULL, 'service', NULL, NULL, 'way/1098703460', 0x00000000010200000002000000f07a1ffde5415e4077c311ff0b6b2d40b599547ee3415e40836852af006b2d40),
(819, 'Acme Road', 'residential', NULL, NULL, 'way/1098703461', 0x00000000010200000002000000bf9f75e8cf415e40b5c766a2636a2d40f631d582cd415e40851d6beb4c6a2d40),
(820, NULL, 'residential', NULL, NULL, 'way/1098703462', 0x000000000102000000020000003253ffc5d8415e409f3fc80d1a692d4025b616c1da415e40be8b529d69692d40),
(821, 'Leo Street', 'service', NULL, NULL, 'way/1098708531', 0x0000000001020000000300000047e0b4850c425e40437d810f146a2d407cdc6dcd0c425e40e4576254086a2d408299a5530d425e4004691030046a2d40),
(822, 'Aries Street', 'residential', NULL, NULL, 'way/1098708532', 0x000000000102000000030000008b12995e07425e40d9f9c8f7d6692d402c97321507425e409e83c2fb056a2d40149d1b8906425e401e6ff25b746a2d40),
(823, NULL, 'footway', NULL, NULL, 'way/1098709594', 0x000000000102000000020000001bbf4b0405425e403b0f385cf5662d40aaa4a9f905425e40eea53a2ef4662d40),
(824, NULL, 'footway', NULL, NULL, 'way/1098709595', 0x0000000001020000000a000000aaa4a9f905425e40eea53a2ef4662d40d9afe02307425e406c9f443af2662d4061ef0fa507425e40993f4bfcf6662d40d41bff4f0f425e4039cf7ddef9662d406d13382314425e4046a68d3402672d40704b9af518425e4018bbd80f0c672d40e7a6727f1a425e4092a7f63306672d40c299a95a1c425e404cfe277ff7662d40011e071420425e400d7a257fe6662d408e67864325425e40af4912dfe4662d40),
(825, NULL, 'service', NULL, NULL, 'way/1098709598', 0x0000000001020000000c00000069cfc02305425e408680327cfa662d40f7555e9706425e406987646df8662d40ea1ad24d07425e40735188dbfc662d40ce2d196c0f425e40ae3b2707fd662d40eeff88cb16425e405aca43f009672d40762277c718425e40b1fd648c0f672d405ef415a419425e40b1d58adb0d672d4069577c9e1a425e40ae10566309672d4045d7851f1c425e40d2110a5bfd662d40b6300bed1c425e4035c291f6f5662d408b49c9bc1f425e40f4fdd478e9662d404ceb257c25425e40488c9e5be8662d40),
(826, NULL, 'service', NULL, NULL, 'way/1098709741', 0x00000000010200000002000000bfcb56a8ff415e403f30ecd56c662d40bfffa03ffe415e40b0b783c76d662d40),
(827, 'Butalid Road', 'service', 'yes', NULL, 'way/1098709742', 0x000000000102000000020000009313927131425e40e0ede64e55662d40fd1cd59f33425e40b545e39a4c662d40),
(828, NULL, 'service', NULL, NULL, 'way/1098710053', 0x000000000102000000030000007430517328425e406ef8dd74cb662d403cc093162e425e40f07c5061b6662d4059bcfd5e2f425e40751daa29c9662d40),
(829, NULL, 'service', NULL, NULL, 'way/1098714384', 0x00000000010200000002000000fc1873d792425e403ef3284b63662d403d1c6ed193425e40d855928664662d40),
(830, NULL, 'service', NULL, NULL, 'way/1098714385', 0x00000000010200000002000000bcd3f8e090425e40103345ca60662d40fc1873d792425e403ef3284b63662d40),
(831, NULL, 'service', NULL, NULL, 'way/1098714386', 0x000000000102000000040000003d1c6ed193425e40d855928664662d406c9ad25595425e40075e2d7766662d40cb29a67796425e40161b4ef454662d40e5c5d33c91425e40dd0bcc0a45662d40),
(832, NULL, 'service', NULL, NULL, 'way/1100972937', 0x00000000010200000002000000cef863ffe1425e4072bb3c4272672d4093e34ee9e0425e40d16dd3e98a672d40),
(833, NULL, 'footway', NULL, NULL, 'way/1100973356', 0x00000000010200000004000000729a4f67b8425e40ab0bd352d4682d40835ec99fb9425e40f6b292fbc2682d4048fe60e0b9425e40b7a1180fa5682d40eee30dd5b9425e4016c330bb82682d40),
(834, NULL, 'service', NULL, NULL, 'way/1100981760', 0x00000000010200000002000000f94cf6cfd3425e405280289831692d40056eddcdd3425e407407567a12692d40),
(835, 'Taurus Street', 'residential', NULL, NULL, 'way/1100984569', 0x00000000010200000006000000623da4ce92425e401c9029c4c8672d400e5652dd92425e40807d74eaca672d40c7a6f0fb92425e4085628621cd672d40a3714d2693425e40cc7edde9ce672d40d8840f8093425e409b36887bd1672d40f446f7bd97425e40ea0e18daef672d40),
(836, NULL, 'service', NULL, NULL, 'way/1100986170', 0x0000000001020000000200000025bf8fb465425e4060de8893a0682d40838d469968425e40e54f0aa991682d40),
(837, NULL, 'service', NULL, NULL, 'way/1100986171', 0x00000000010200000002000000278925e56e425e401cb62dca6c682d407b794b836c425e4000a370e250682d40),
(838, NULL, 'service', NULL, NULL, 'way/1100986172', 0x000000000102000000020000008fdc3fbb68425e40fec753a060682d401c74aecd6b425e4036188ff74f682d40),
(839, NULL, 'service', NULL, NULL, 'way/1100986884', 0x000000000102000000040000000edaab8f87425e40d8929f9e88672d4091b8c7d287425e40fb905ca38a672d405b74571b88425e4058a192848e672d406dc83f3388425e4019e7cafb93672d40),
(840, NULL, 'service', NULL, NULL, 'way/1100986885', 0x00000000010200000003000000a42c8da985425e40486de2e47e672d402cb1d76086425e40641ef98381672d40081d740987425e40ec996f8e84672d40),
(841, NULL, 'service', NULL, NULL, 'way/1100986886', 0x00000000010200000002000000081d740987425e40ec996f8e84672d400edaab8f87425e40d8929f9e88672d40),
(842, NULL, 'service', NULL, NULL, 'way/1100987547', 0x00000000010200000003000000ca98ccc268425e408cdafd2ac0672d40bfedae5868425e406d59be2ec3672d40d21c59f965425e4053dd6d28c6672d40),
(843, 'Black Quail Street', 'service', NULL, NULL, 'way/1100987548', 0x0000000001020000000300000097aebbd463425e4095922fb2ae672d40206118b064425e40ae0e80b8ab672d401290e51368425e40695abd1ea7672d40),
(844, NULL, 'service', NULL, NULL, 'way/1100987549', 0x000000000102000000020000009721e92e64425e40f3a1557776672d403c88f8e266425e403689e6a672672d40),
(845, NULL, 'residential', NULL, NULL, 'way/1103403919', 0x00000000010200000004000000647d5e4c8e415e40a54c6a68036c2d40f8dad8918f415e407524f2b8036c2d40a54fabe88f415e40ec40e77f036c2d4069be94cb90415e40dd71d41bff6b2d40),
(846, NULL, 'residential', NULL, NULL, 'way/1103403920', 0x00000000010200000007000000fe1076e58e415e406a49ec7f256c2d4088c90a348e415e40c66416461f6c2d40647d5e4c8e415e40a54c6a68036c2d408efc0b4e8e415e40b8335d99016c2d401c89e1348e415e40b90b83e8ff6b2d402349b5f48d415e40c5ed8623fe6b2d400622d5c18b415e404fa9b7abfc6b2d40),
(847, 'Saint Joseph Street', 'residential', NULL, NULL, 'way/1103403921', 0x00000000010200000004000000bcd5ce8b6e415e4021ee450fd76d2d40628acd226f415e40a1191fc1e86d2d4097cba1a06f415e40ff66182df66d2d406744696f70415e4035ce4b6a0d6e2d40),
(848, NULL, 'service', NULL, NULL, 'way/1104338612', 0x000000000102000000030000000b28d4d347425e40db937659026b2d40f95d222848425e405da96741286b2d40fcf61a272a425e40b676ecb13e6b2d40),
(849, NULL, 'footway', NULL, NULL, 'way/1104338613', 0x0000000001020000000f000000fba24e8a20425e40444df4f9286b2d40436c55b71f425e40c8d864e8336b2d400294d0a71f425e4083893f8a3a6b2d4096afcbf01f425e40549e8a65446b2d408ad063ef20425e40f0cd250b4e6b2d40e374ed6621425e400512b985536b2d4030293e3e21425e40f6549808656b2d404eb5166621425e407a00e6b56d6b2d402a4fc53222425e40bb7cebc37a6b2d40952d927623425e409abbf149826b2d40ffc6438424425e40d7e54af37d6b2d400a3e175726425e405652dd126f6b2d40993d1a9826425e40fbac32535a6b2d40a4b4ed6a28425e407ce6f6dc536b2d40fcf61a272a425e40b676ecb13e6b2d40),
(850, NULL, 'service', NULL, NULL, 'way/1104355357', 0x0000000001020000000200000088c90a340e425e4029a8f287b06b2d40b2518ce20b425e40bf45274bad6b2d40),
(851, NULL, 'service', NULL, NULL, 'way/1104355358', 0x000000000102000000020000000c10bba50b425e40271186a6916b2d40dc74159c0b425e40234c512e8d6b2d40),
(852, NULL, 'service', NULL, NULL, 'way/1104355359', 0x000000000102000000030000001a01704713425e40dd330175b96b2d4062ca767412425e4012dfe412a26b2d40a120c20916425e401717a29e996b2d40),
(853, 'Saint Joseph Street', 'residential', NULL, NULL, 'way/1104358323', 0x00000000010200000004000000794b283394415e40c1f00005cd6d2d403831242793415e4088d68a36c76d2d404455a75e92415e4055e9dd0ec36d2d40b00e362b91415e40b09c73a6bf6d2d40),
(854, 'Pablo dela Cruz Street', 'residential', NULL, NULL, 'way/1104358324', 0x00000000010200000003000000d942908392415e40c2da183be16d2d40af3610dc92415e404e8e4cd1db6d2d408bd35ae292415e408ac0a26cdb6d2d40),
(855, NULL, 'service', NULL, NULL, 'way/1104359258', 0x000000000102000000020000005dc30c8da7415e405d137761106d2d40ced77624a8415e409bea24b6166d2d40),
(856, NULL, 'service', NULL, NULL, 'way/1104359260', 0x00000000010200000003000000b0fc9efd6d415e40a700bd152e6c2d4009e643ab6e415e40cf1c48cd0d6c2d40867a55c26e415e406045fc79096c2d40),
(857, 'Recto Street', 'residential', NULL, NULL, 'way/1104359263', 0x000000000102000000020000002ea0617b77415e40a12c7c7dad6b2d4078da75ca7e415e40eb13e5773f6b2d40),
(858, NULL, 'service', NULL, NULL, 'way/1104540224', 0x00000000010200000002000000effa71a0ac415e40b0a7c244286b2d40b9e177d3ad415e4003a61d48286b2d40),
(859, NULL, 'residential', NULL, NULL, 'way/1104541839', 0x000000000102000000030000003c9bfae538415e400369b576916c2d40a77c636339415e406e3315e2916c2d40e525ff933f415e407e4adfb5956c2d40),
(860, NULL, 'service', NULL, NULL, 'way/1104542422', 0x000000000102000000020000004add843158415e40ac27a902a46c2d406dad2f125a415e4094837e4ba56c2d40),
(861, NULL, 'service', NULL, NULL, 'way/1104849231', 0x0000000001020000000200000048f542a6a1415e40023917354e6d2d402aabe97aa2415e40dccfce0e5d6d2d40),
(862, NULL, 'service', NULL, NULL, 'way/1104849232', 0x00000000010200000002000000a7abe05ce8415e402e895869f76c2d40efb902c0e7415e409b68a1aeff6c2d40),
(863, NULL, 'service', NULL, NULL, 'way/1104849233', 0x00000000010200000002000000600fdc37ad415e40b6e7e8a7ee6c2d40f4273b47ae415e40786ae4a9fd6c2d40),
(864, NULL, 'service', NULL, NULL, 'way/1104849234', 0x00000000010200000002000000cf424cd3b1415e408bb26d07d96c2d405857056ab1415e40c7c7ddd6cc6c2d40),
(865, 'Calugas Street', 'residential', NULL, NULL, 'way/1115626056', 0x00000000010200000002000000d3f9f02cc1415e4076c6527f186c2d405b61fa5ec3415e4049ec7f25fc6b2d40),
(866, NULL, 'service', NULL, NULL, 'way/1115626155', 0x00000000010200000004000000d8385101e6415e406a62cb3c036c2d401234c1cbe7415e40282b86ab036c2d404563edefec415e40ebf5381d126c2d409cad179ef2415e4004ff00101c6c2d40),
(867, NULL, 'service', NULL, NULL, 'way/1154436618', 0x00000000010200000002000000865b994b05425e405340daff00672d40217c838a05425e40361c3b4d0b672d40),
(868, NULL, 'residential', NULL, NULL, 'way/1172642035', 0x0000000001020000000200000029e1534a99415e40d05be102756b2d40acf01deb98415e40aa5e23ee566b2d40),
(869, NULL, 'residential', NULL, NULL, 'way/1172642036', 0x00000000010200000002000000cff4126399415e40610619b7876b2d4029e1534a99415e40d05be102756b2d40),
(870, NULL, 'residential', NULL, NULL, 'way/1172642037', 0x00000000010200000002000000e0fda7d19a415e403cfe66bd736b2d4004d7265f9a415e406e2ccd52576b2d40),
(871, 'Saint Thaddeus Street', 'tertiary', 'no', NULL, 'way/1184323977', 0x00000000010200000006000000b7d100de02435e40e7db27ec47672d40c3de7a0302435e4071fcf5af51672d408e13701901435e4083e0f1ed5d672d40d061bebc00435e403744262a65672d406bca5f6b00435e401c881ba66c672d405f645d3700435e4064b95b4876672d40),
(872, 'Saint John Street', 'tertiary', NULL, NULL, 'way/1184323978', 0x000000000102000000020000008145d9b603435e40216239f878672d405f645d3700435e4064b95b4876672d40);
INSERT INTO `streets` (`Id`, `Name`, `Highway`, `Oneway`, `OldName`, `StreetId`, `Geometry`) VALUES
(873, NULL, 'path', NULL, NULL, 'way/1192332932', 0x00000000010200000007000000864bd8c83f4b5e402ba5677a89392c40b528fdce404b5e409c0425bb88392c408a3e1f65444b5e40bbb14577b5392c40bf7c57a9454b5e40e8436161d2392c4029893611474b5e4002452c62d8392c405eb3017d474b5e406d910fd5ef392c40ee5c18e9454b5e40bbef181efb392c40),
(874, NULL, 'service', NULL, NULL, 'way/1209714273', 0x000000000102000000020000009bcb0d86ba415e4061ec736b886c2d40cadc7c23ba415e40102ed3e5836c2d40),
(875, NULL, 'service', NULL, NULL, 'way/1227161435', 0x00000000010200000002000000159ada087a425e40053f60d4a46a2d400435215278425e4057d526a9a76a2d40),
(876, NULL, 'footway', NULL, NULL, 'way/1227161436', 0x000000000102000000030000008ef3ed1376425e40f5a512f9896a2d40b139628877425e404fc939b1876a2d40b05ea0ff79425e40f2b803d0836a2d40),
(877, NULL, 'service', NULL, NULL, 'way/1227161437', 0x0000000001020000000300000042f1be8550425e40cc07043a936a2d4031a072a74f425e409c4f1dab946a2d40aec4f29d4e425e404274ad62966a2d40),
(878, NULL, 'footway', NULL, NULL, 'way/1227161438', 0x000000000102000000030000002005f46764425e40178c005dea6a2d409df8c50064425e40ae0c4f54db6a2d40b5f578c663425e40be4eeacbd26a2d40),
(879, NULL, 'service', NULL, NULL, 'way/1243150223', 0x00000000010200000002000000f17332279e415e403895568d6f6d2d40516b9a779c415e40b8f6f4c76a6d2d40),
(880, NULL, 'service', NULL, NULL, 'way/1243377389', 0x00000000010200000002000000c8ab185355425e407a4db450d7672d407a50508a56425e4072a36da1d0672d40),
(881, NULL, 'service', NULL, NULL, 'way/1243378356', 0x00000000010200000002000000c8bf852b56425e40f2a66ca2e0672d40d9b1118857425e40d8351081d9672d40),
(882, NULL, 'service', NULL, NULL, 'way/1243379266', 0x00000000010200000002000000bf5afff85c425e407777ae3951682d401741086d5e425e40ae5f556243682d40),
(883, NULL, 'service', NULL, NULL, 'way/1243379267', 0x00000000010200000002000000fc22fce659425e4010b633a726682d40668bff965b425e407e9873df20682d40),
(884, NULL, 'service', NULL, NULL, 'way/1243381069', 0x00000000010200000002000000f534bb4967425e404deb803518682d4059c97d6168425e400ecc1b7112682d40),
(885, NULL, 'service', NULL, NULL, 'way/1243381070', 0x00000000010200000002000000f8808af46c425e4095568d6f39682d4024264d2869425e4028d8da560e682d40),
(886, NULL, 'service', NULL, NULL, 'way/1243381071', 0x0000000001020000000200000017b776476b425e40226e4e2503682d40eb11b4136f425e408fec003e2e682d40),
(887, NULL, 'service', NULL, NULL, 'way/1243967816', 0x00000000010200000002000000b9b0242fa1415e40476062e2456d2d4048f542a6a1415e40023917354e6d2d40),
(888, NULL, 'footway', NULL, NULL, 'way/1245810161', 0x000000000102000000040000008552c59e07425e402d7b12d89c6b2d40c744eff906425e40ece52d0db26b2d402cf6f29606425e40a31694b3c16b2d40866f062406425e40b6c7c15bd66b2d40),
(889, 'Ivory Street', 'residential', NULL, NULL, 'way/1245810162', 0x00000000010200000004000000eb85a7fc10425e402bcd9ce4fd6a2d40c237a85810425e4033a3c453346b2d401b52fb6310425e4004b80f2f3e6b2d4021b30ea210425e408e684cd2466b2d40),
(890, 'Orange Street', 'residential', NULL, NULL, 'way/1245810163', 0x000000000102000000060000008552c59e07425e402d7b12d89c6b2d40f078495208425e40d4a29982906b2d40e36bcf2c09425e40058651b5826b2d403c9a8f100a425e40ec7c89c2786b2d405990c1e50c425e40f16f86d1626b2d4021b30ea210425e408e684cd2466b2d40),
(891, NULL, 'service', NULL, NULL, 'way/1245811443', 0x000000000102000000020000005cf635dc11425e405febf769816a2d40b5e276c311425e406d7d47437c6a2d40),
(892, NULL, 'service', NULL, NULL, 'way/1246242755', 0x000000000102000000020000006f17f5a427425e4084ea8b29fd692d40875c5fda26425e4027da5548f9692d40),
(893, NULL, 'service', NULL, NULL, 'way/1246245118', 0x000000000102000000030000001fb0bcf52b425e4030a182c30b6a2d40bdace4be30425e40418f62cad1692d40c87c40a033425e40db526232b0692d40),
(894, NULL, 'service', NULL, NULL, 'way/1246245119', 0x0000000001020000000300000060f6fc7a4f425e406d3f749c366a2d40cd2e29884b425e40ee8a2a0d466a2d4016461f9848425e405491651c7e6a2d40),
(895, NULL, 'service', NULL, NULL, 'way/1246245120', 0x0000000001020000000200000075e0415832425e40646c32f499692d40bcba192433425e408687d5c4a7692d40),
(896, NULL, 'service', NULL, NULL, 'way/1247032634', 0x000000000102000000020000008c5f1d6c56415e40b9c1f5cda26c2d404add843158415e40ac27a902a46c2d40),
(897, NULL, 'service', NULL, NULL, 'way/1247032891', 0x0000000001020000000200000041bd74ee51415e4006de24613a6c2d4041d47d0052415e40270fb0fb336c2d40),
(898, NULL, 'service', NULL, NULL, 'way/1247034697', 0x00000000010200000002000000f75d6cb562415e40f3f400cc6b6b2d4068a384aa62415e409dfea2ba6f6b2d40),
(899, NULL, 'service', NULL, NULL, 'way/1247034698', 0x00000000010200000003000000e63dce3461415e40ab1386b7bd6b2d403acf33515f415e408ed20039bc6b2d4090dc9a745b415e4006578a2eb96b2d40),
(900, NULL, 'service', NULL, NULL, 'way/1247034699', 0x0000000001020000000200000090dc9a745b415e4006578a2eb96b2d40677dca3159415e406d3cd862b76b2d40),
(901, NULL, 'service', NULL, NULL, 'way/1247035919', 0x00000000010200000002000000d0c254e95d415e404bd356db036b2d4030fc3b365d415e40e60de665036b2d40),
(902, NULL, 'service', NULL, NULL, 'way/1247035920', 0x0000000001020000000200000030fc3b365d415e40e60de665036b2d407e9fbb6e5b415e40eda2433b026b2d40),
(903, NULL, 'service', NULL, NULL, 'way/1247036725', 0x000000000102000000020000007267cb5e5b415e40441e1c47076b2d4043e966da59415e40cd49deef066b2d40),
(904, NULL, 'service', NULL, NULL, 'way/1247036726', 0x000000000102000000020000005b423ee859415e4094e7b0b1016b2d407e9fbb6e5b415e40eda2433b026b2d40),
(905, NULL, 'service', NULL, NULL, 'way/1247036727', 0x0000000001020000000200000010e84cda54415e4053d048dfff6a2d405b423ee859415e4094e7b0b1016b2d40),
(906, 'Magsaysay Extension', 'residential', NULL, NULL, 'way/1247040903', 0x000000000102000000020000005dbf057e79415e40b939f0c5726a2d406fa6f8ae77415e40c02500ff946a2d40),
(907, 'Marcos Street', 'residential', NULL, NULL, 'way/1247040904', 0x000000000102000000040000006096d123a1415e403ce3569cc56a2d40e3e71ac1a1415e40a06010a2c66a2d40d190966fa2415e404daa6c0ec66a2d4056702eb4a9415e40a16efb79ae6a2d40),
(908, NULL, 'service', NULL, NULL, 'way/1247040905', 0x000000000102000000060000007e213f7672415e4012e390685d6a2d40724573ae72415e401bb8a8bb576a2d40133d3abf72415e40f464485f526a2d40724573ae72415e40a37ecd284c6a2d40967a168472415e408fcaa88d456a2d40de8bd42071415e409985d107266a2d40),
(909, NULL, 'service', NULL, NULL, 'way/1247040906', 0x00000000010200000002000000ff32294f6a415e4028bdca35606b2d408ed36b0e6b415e40a2c6ce25666b2d40),
(910, NULL, 'service', NULL, NULL, 'way/1247040907', 0x000000000102000000070000008ed36b0e6b415e40a2c6ce25666b2d40bdca35606b415e40a6d3ba0d6a6b2d40b1ee69986b415e40b6ea84e16d6b2d40349f73b76b415e40ac85feae746b2d403a8d599b6b415e40f1619bf97a6b2d4094347f4c6b415e4029345a58816b2d40060da25a69415e403eb2b96a9e6b2d40),
(911, NULL, 'residential', NULL, NULL, 'way/1247040908', 0x00000000010200000002000000e3a430ef71415e40afb6bd384c6b2d40d571a19776415e40f96c78d55e6b2d40),
(912, NULL, 'residential', NULL, NULL, 'way/1247040909', 0x0000000001020000000200000066f3dd5273415e401a6f2bbd366b2d403a79910978415e407a19c5724b6b2d40),
(913, NULL, 'service', NULL, NULL, 'way/1247052377', 0x0000000001020000000200000072778ce1a0415e4024624a24d16b2d407ec9213da0415e40d11e2fa4c36b2d40),
(914, NULL, 'service', NULL, NULL, 'way/1247052378', 0x00000000010200000002000000ada64643a1415e406161d229d96b2d4072778ce1a0415e4024624a24d16b2d40),
(915, NULL, 'service', NULL, NULL, 'way/1247052379', 0x0000000001020000000200000014611e8d9e415e4085dcfb0a886b2d4008dedad39f415e4011bf0754a46b2d40),
(916, NULL, 'service', NULL, NULL, 'way/1247052380', 0x000000000102000000020000002642d94a9e415e40edb94c4d826b2d4014611e8d9e415e4085dcfb0a886b2d40),
(917, NULL, 'service', NULL, NULL, 'way/1247052382', 0x0000000001020000000200000057b5a4a39c415e403c3833558b6b2d40c23ae9d89c415e40154a7034916b2d40),
(918, NULL, 'service', NULL, NULL, 'way/1247052383', 0x0000000001020000000200000069ad68739c415e4062de3e06866b2d4057b5a4a39c415e403c3833558b6b2d40),
(919, NULL, 'service', NULL, NULL, 'way/1247052384', 0x000000000102000000020000008e33976599415e40764aac318d6b2d40cff4126399415e40610619b7876b2d40),
(920, NULL, 'service', NULL, NULL, 'way/1247052385', 0x00000000010200000002000000230a777899415e409e5c5320b36b2d408e33976599415e40764aac318d6b2d40),
(921, NULL, 'residential', NULL, NULL, 'way/1247052386', 0x00000000010200000002000000875682209b415e40f036ca55876b2d40e0fda7d19a415e403cfe66bd736b2d40),
(922, NULL, 'service', NULL, NULL, 'way/1247052602', 0x0000000001020000000200000054eef439ad415e402497ff907e6b2d40b982b751ae415e40198d21a57e6b2d40),
(923, NULL, 'service', NULL, NULL, 'way/1247052603', 0x000000000102000000020000004d599764ae415e40fde9f5dd636b2d40e4ce96bdb6415e408fdfdbf4676b2d40),
(924, NULL, 'service', NULL, NULL, 'way/1247052604', 0x0000000001020000000200000060f536ecad415e407406eba4636b2d404d599764ae415e40fde9f5dd636b2d40),
(925, NULL, 'service', NULL, NULL, 'way/1247052605', 0x00000000010200000002000000d1e1c6d2ac415e408d3a843b616b2d4060f536ecad415e407406eba4636b2d40),
(926, 'Sikatuna Street', 'residential', NULL, NULL, 'way/1247054811', 0x00000000010200000006000000bdc05197b1415e409fee97aa0f6b2d402874a8f0b1415e40d443d900116b2d40ec6f6479b2415e40dfbd480d126b2d40158a1986b4415e40cdf6329b116b2d40387705ecb4415e4080457efd106b2d402cb24236b5415e403a2927350f6b2d40),
(927, 'Sikatuna Street', 'residential', NULL, NULL, 'way/1247054812', 0x00000000010200000007000000247ec51aae415e40ca1efc1fbb6a2d40f4e21f11ae415e40c8b667f1bd6a2d40cb7a7b21ae415e406241abddc06a2d403b472e49af415e406540aceddc6a2d40bd361b2bb1415e40956c2bac0a6b2d408de09057b1415e4082f5c99b0d6b2d40bdc05197b1415e409fee97aa0f6b2d40),
(928, 'Sikatuna Street', 'residential', NULL, NULL, 'way/1247054813', 0x0000000001020000000600000045b52d6fb3415e4083f0b270a36a2d404514eef0b2415e405fd218ada36a2d400ace2a7db2415e40e120c610a56a2d40711871a6ae415e40a9d08ab9b56a2d401ea7e848ae415e407e8d2441b86a2d40247ec51aae415e40ca1efc1fbb6a2d40),
(929, NULL, 'service', NULL, NULL, 'way/1247054814', 0x0000000001020000000a000000bc2d477eb3415e40366acf76966a2d4033a6608db3415e40cf8f75278e6a2d4098e19a96b3415e4077f4bf5c8b6a2d40fd4ae7c3b3415e4037250ffa886a2d40aabfb91ab4415e405616e016876a2d409dda19a6b6415e400ebdc5c37b6a2d4037120df7b6415e40bc96900f7a6a2d4043780f2bb7415e406f754a51786a2d40cc441152b7415e407c9f05fc756a2d4037b34c75b7415e40cb48bda7726a2d40),
(930, NULL, 'service', NULL, NULL, 'way/1247054815', 0x00000000010200000006000000c257cfa4a8415e400ee3c9c91f6b2d402df41ceca8415e40d6051786236b2d40a3df6355a9415e402ea1cc50266b2d409171d6f1a9415e40e6d429ea276b2d40fcae63b7aa415e405da96741286b2d40effa71a0ac415e40b0a7c244286b2d40),
(931, NULL, 'service', NULL, NULL, 'way/1247058620', 0x0000000001020000000200000009d4ac7dcb415e408eee7b2f196a2d4035762e31bb415e4063d6e65a0f6a2d40),
(932, NULL, 'service', NULL, NULL, 'way/1247058621', 0x00000000010200000005000000f631d582cd415e40851d6beb4c6a2d402c312a04cd415e40863d48aa4a6a2d40a3daf170cc415e400af4893c496a2d400930d1c5cb415e40bd42d59e486a2d4086b07504cb415e40f9742b3a486a2d40),
(933, NULL, 'service', NULL, NULL, 'way/1247058622', 0x0000000001020000000500000035762e31bb415e4063d6e65a0f6a2d40ee0e84bfba415e40aca289c10d6a2d4083442454ba415e4059349d9d0c6a2d40eefa16e7b9415e40067ef9090c6a2d409c4aabc6b7415e40a10040040b6a2d40),
(934, NULL, 'service', NULL, NULL, 'way/1247058623', 0x00000000010200000002000000e8f28bb7ba415e40ce5c96653e6a2d40676897cab6415e40cbdf185d396a2d40),
(935, NULL, 'service', NULL, NULL, 'way/1247058624', 0x00000000010200000002000000e8f28bb7ba415e40ce5c96653e6a2d4035762e31bb415e4063d6e65a0f6a2d40),
(936, NULL, 'service', NULL, NULL, 'way/1247058792', 0x0000000001020000000200000095319985d1415e40c4c6061c53692d40ee1dda6cd1415e40671b6e765a692d40),
(937, NULL, 'service', NULL, NULL, 'way/1247064042', 0x00000000010200000002000000f5c6ffd3c3415e4093b76d2931692d402aa913d0c4415e4014121f8e64692d40),
(938, NULL, 'service', NULL, NULL, 'way/1247066066', 0x00000000010200000002000000006f8104c5415e40e3f9b1eec4692d4054e98255d0415e407af18f08d7692d40),
(939, NULL, 'service', NULL, NULL, 'way/1247066067', 0x0000000001020000000700000095d233bdc4415e40dbc6fa61df692d402a08d451c4415e40c29261cbe1692d4031557ab7c3415e40f7e7a221e3692d403e31a138b6415e4062b2028de3692d40ce9bd4e1b2415e40c7777302e4692d40576b7242b2415e40ebddc435e3692d402e4b85c2b1415e406f2475a7e0692d40),
(940, NULL, 'footway', NULL, NULL, 'way/1247066068', 0x00000000010200000002000000c7a17e17b6415e409c093ce6f2692d400b1fb699af415e4090ff5dfaf2692d40),
(941, NULL, 'footway', NULL, NULL, 'way/1247066069', 0x00000000010200000004000000f7faa424b5415e40fab1eec4516a2d40338cbb41b4415e406d09af134d6a2d40d6afcff7ae415e400b027514316a2d401801bad4ad415e404904f40c2b6a2d40),
(942, NULL, 'footway', NULL, NULL, 'way/1247066070', 0x000000000102000000090000003e31a138b6415e4062b2028de3692d40c7a17e17b6415e409c093ce6f2692d40c7003f99b5415e40bec3488a236a2d40a36f777bb5415e40093543aa286a2d406e73be33b5415e40dd8948032e6a2d40fdba78e4b4415e4027fb4223336a2d4062b197b7b4415e4096d28e76376a2d40921e2b9db4415e406a2794cf3c6a2d40338cbb41b4415e406d09af134d6a2d40),
(943, 'Bougainvilla Street', 'service', NULL, NULL, 'way/1247068250', 0x000000000102000000020000009a2e7a5df5415e40bdd17def25672d404b1d893cee415e4012baf0283a672d40),
(944, 'Bougainvilla Street', 'service', 'yes', NULL, 'way/1247068251', 0x00000000010200000003000000b1dd3d40f7415e40f7eeeab01d672d409f9dc200f8415e40fecbfff51b672d40038ea960f9415e40987620a11c672d40),
(945, 'Bougainvilla Street', 'service', 'yes', NULL, 'way/1247068252', 0x00000000010200000003000000038ea960f9415e40987620a11c672d40757a3947f8415e401e424b0d23672d4087bab486f7415e406a6391cb24672d40),
(946, NULL, 'footway', NULL, NULL, 'way/1247068254', 0x000000000102000000020000005ddc4603f8415e406fbc3b3256672d407033cb54f7415e405726fc523f672d40),
(947, NULL, 'footway', NULL, NULL, 'way/1247068255', 0x00000000010200000006000000c741ae79fa415e40404bfcf61a672d405025b9b2fa415e40c3d66ce525672d40d3d5c2d1fa415e40485ae0e12c672d400f924fd9fa415e400fcde1ff33672d40d3d5c2d1fa415e40e84eb0ff3a672d40b504cf73fa415e40e8d0330752672d40),
(948, NULL, 'service', NULL, NULL, 'way/1247068256', 0x00000000010200000006000000d19a7a38dc415e40f5752a2a2c662d4012143fc6dc415e40e5863a072a662d40836dc493dd415e40bbf31f2d29662d40b0fc9efded415e40b3a08be145662d403e6fcf98ee415e40466e974748662d40099e8c3bef415e408665225b4c662d40),
(949, NULL, 'footway', NULL, NULL, 'way/1247068257', 0x00000000010200000002000000218dafe279415e409333b9bd49682d409ec59cb179415e40cef2864556682d40),
(950, NULL, 'footway', NULL, NULL, 'way/1247068258', 0x00000000010200000002000000d875b9d27c415e40b31d9d0480682d40d7135d177e415e40d268177893682d40),
(951, NULL, 'footway', NULL, NULL, 'way/1247068259', 0x000000000102000000020000009ec59cb179415e40cef2864556682d40d875b9d27c415e40b31d9d0480682d40),
(952, NULL, 'service', NULL, NULL, 'way/1247068260', 0x0000000001020000000e00000022ad8ca177415e4054466d2c72692d406f8c536378415e407594de9277692d408c88bdab79415e40c04d90227c692d40671998cb7c415e4060257a747e692d409ce1067c7e415e407e3e25427e692d40bf277bf07f415e40a8f11cdb7c692d40bef3305981415e408c40063c7a692d40a535615683415e408fa09d7873692d40ce7d288785415e402716f88a6e692d40bbdeecc586415e40aacc391d6d692d40045b80118f415e40861e317a6e692d4057e0754790415e40c70dbf9b6e692d40f7787cd690415e401b54d10e6e692d4080b8ab5791415e402231e6536c692d40),
(953, NULL, 'service', NULL, NULL, 'way/1247083481', 0x00000000010200000002000000d12cbfc238425e403a90f5d4ea672d40072fb07d37425e40298128f3ea672d40),
(954, NULL, 'service', NULL, NULL, 'way/1247083482', 0x00000000010200000002000000ef14bc3239425e408af5fc1f16682d40965cc5e237425e40bfdaac5516682d40),
(955, NULL, 'service', NULL, NULL, 'way/1247083483', 0x00000000010200000005000000965cc5e237425e40bfdaac5516682d409c64501237425e40bfdaac5516682d40d823795336425e40ad1397e315682d40fd5bb86235425e4078be558d14682d40e951a7f22c425e40a0d7e95102682d40),
(956, NULL, 'service', NULL, NULL, 'way/1247083484', 0x00000000010200000002000000f761180b1e425e400dcbfa287e672d40b52ad3791e425e40757286e28e672d40),
(957, NULL, 'service', NULL, NULL, 'way/1247083485', 0x00000000010200000002000000f452b1312f425e40ae7e11d9ac672d404d0e44bb2f425e408109dcba9b672d40),
(958, NULL, 'service', NULL, NULL, 'way/1247083486', 0x00000000010200000002000000ec91bc291b425e405def4806ca672d40fee8407b1a425e40615dcb1aab672d40),
(959, 'Beta Street', 'residential', NULL, NULL, 'way/1247083487', 0x000000000102000000020000004837c2a222425e40e3361ac05b682d40bf8465c721425e40ba6d3a5d71682d40),
(960, NULL, 'residential', 'no', NULL, 'way/1247084874', 0x00000000010200000002000000eb63f49235425e405ce674594c682d40ead0e97937425e409818cbf44b682d40),
(961, NULL, 'residential', 'no', NULL, 'way/1247084875', 0x000000000102000000020000001f717e7937425e4019e2fd5d44682d4048d04ebc39425e40b41c8de843682d40),
(962, NULL, 'residential', NULL, NULL, 'way/1247084876', 0x000000000102000000020000004871e9f32c425e4098fbe42840682d40b9fb1c1f2d425e407c58b96125682d40),
(963, NULL, 'service', NULL, NULL, 'way/1247085164', 0x0000000001020000000200000048d04ebc39425e40b41c8de843682d400bc96e0b3b425e40e949f48d43682d40),
(964, NULL, 'service', NULL, NULL, 'way/1247087578', 0x00000000010200000002000000b857e6ad3a425e40a3b9049612682d404818062c39425e4073918ce612682d40),
(965, NULL, 'service', NULL, NULL, 'way/1247090970', 0x000000000102000000020000004ce3175e49425e405f44db3175672d4015996f334b425e40935c59fd6c672d40),
(966, NULL, 'service', NULL, NULL, 'way/1247090971', 0x000000000102000000020000004e7cb5a338425e40520548d9c7672d4036374b6e39425e40b85a272ec7672d40),
(967, NULL, 'steps', NULL, NULL, 'way/1247093893', 0x000000000102000000020000005a643bdf4f425e40764aac318d672d40c0d023464f425e406d58ae1287672d40),
(968, NULL, 'steps', NULL, NULL, 'way/1247093894', 0x00000000010200000002000000aef5a0fb4d425e403bc5aa4198672d40146289624d425e4032d3ac2292672d40),
(969, 'Butalid Road', 'service', 'yes', NULL, 'way/1247254790', 0x00000000010200000003000000c96b6f0132425e407dadf0d35d662d409386bfcb31425e40ff4355a75e662d4076b867a730425e40fd039b2963662d40),
(970, 'Butalid Road', 'service', NULL, NULL, 'way/1247254791', 0x0000000001020000000200000076b867a730425e40fd039b2963662d40b8c19a1430425e405b3fa2ae5a662d40),
(971, 'Butalid Road', 'service', 'yes', NULL, 'way/1247254792', 0x00000000010200000003000000b8c19a1430425e405b3fa2ae5a662d405e2ee23b31425e4063844b2256662d409313927131425e40e0ede64e55662d40),
(972, 'Butalid Road', 'service', 'yes', NULL, 'way/1247254793', 0x000000000102000000030000005cf45f3134425e40ecf7c43a55662d40b614ebaf32425e40c00413245b662d40c96b6f0132425e407dadf0d35d662d40),
(973, NULL, 'service', NULL, NULL, 'way/1247254794', 0x00000000010200000002000000a3efc91efc415e404ae53796c1662d404658f90af7415e405d3fb3dab2662d40),
(974, NULL, 'service', NULL, NULL, 'way/1247254795', 0x00000000010200000002000000e43e83972a425e40c69970f959662d40a75f7d972d425e40f5edc96889662d40),
(975, NULL, 'service', NULL, NULL, 'way/1247254796', 0x0000000001020000000900000053f06f2b18425e404951c2a794662d406ad37da518425e404e36d4de96662d406a5db41119425e40b2b38de497662d407c24ca8319425e40ee9d2c1098662d40ed0a22f719425e40d619df1797662d40f3823e471a425e403dff2c4c95662d406f4562821a425e407f0e982c93662d40e1b88c9b1a425e40216ef36b90662d40ecf07cab1a425e401e81e4428a662d40),
(976, NULL, 'service', NULL, NULL, 'way/1247254797', 0x000000000102000000020000006d9a2d0f08425e400e10711871662d40be2d58aa0b425e400206932c71662d40),
(977, NULL, 'service', NULL, NULL, 'way/1247254798', 0x0000000001020000000300000031dea00708425e4097303fdc7a662d406d9a2d0f08425e400e10711871662d405b74571b08425e40ceb348c961662d40),
(978, NULL, 'service', NULL, NULL, 'way/1247254799', 0x0000000001020000000400000052b06b2002425e40f39e14f769662d40bec51e3501425e404150c9946a662d409532045b00425e4022ef66576b662d40bfcb56a8ff415e403f30ecd56c662d40),
(979, NULL, 'service', NULL, NULL, 'way/1247254800', 0x00000000010200000002000000d4b3c5da04425e40f175638bee662d405c77f35407425e40fd378a07ef662d40),
(980, NULL, 'service', NULL, NULL, 'way/1247254801', 0x000000000102000000050000001494a295fb415e40e9d907b4cf662d40f3d2a81b03425e40f1587dbfe2662d4046a055c103425e4031282e22e5662d408d63247b04425e40e2a65027ea662d40d4b3c5da04425e40f175638bee662d40),
(981, NULL, 'service', NULL, NULL, 'way/1247254802', 0x000000000102000000020000004ddc8541f4415e40b6172c30bf662d40490e7d1cf2415e40ce041e73f9662d40),
(982, NULL, 'service', 'yes', NULL, 'way/1249415713', 0x00000000010200000006000000b8a51f1e53425e4023b3c414f66a2d40137cd3f459425e40e71bd13deb6a2d40c93ec8b260425e409370218fe06a2d409df8c50064425e40ae0c4f54db6a2d40f838d3846d425e404a928c41cc6a2d40aabb0dc578425e408977256eba6a2d40),
(983, NULL, 'service', 'no', NULL, 'way/1249416767', 0x0000000001020000000200000057337c5578425e4008550f3dce692d4027f15e5a79425e4099c57a59c9692d40),
(984, NULL, 'footway', NULL, NULL, 'way/1253823877', 0x0000000001020000000200000025f8f076ce425e4028ff493261662d401b48179bd6425e4074a213f879662d40),
(985, NULL, 'footway', NULL, NULL, 'way/1253823878', 0x00000000010200000002000000b9212125d1425e40a779c7293a662d406e9c5e73d8425e4031ff32294f662d40),
(986, NULL, 'service', NULL, NULL, 'way/1253823879', 0x000000000102000000040000006e9c5e73d8425e4031ff32294f662d40321180c9d7425e400b4e33935e662d400331bf89d7425e40f66e3d5464662d401b48179bd6425e4074a213f879662d40),
(987, NULL, 'footway', NULL, NULL, 'way/1253823880', 0x000000000102000000020000001fa8aed7cf425e401f381db74e662d400331bf89d7425e40f66e3d5464662d40),
(988, NULL, 'footway', NULL, NULL, 'way/1253823881', 0x00000000010200000003000000b9212125d1425e40a779c7293a662d401fa8aed7cf425e401f381db74e662d4025f8f076ce425e4028ff493261662d40),
(989, 'Carlos Street', 'tertiary', 'no', NULL, 'way/1253823882', 0x000000000102000000030000008bc0fd25ce425e4082dceade2f672d4025cade52ce425e40a115736b2d672d40e3303d06d0425e4007e9ceb815672d40),
(990, NULL, 'service', NULL, NULL, 'way/1253829510', 0x000000000102000000020000006cb64d4cf2425e403875d487e4662d4060394206f2425e4051f1248ee1662d40),
(991, NULL, 'residential', NULL, NULL, 'way/1253846051', 0x00000000010200000004000000d6308d70a4425e408a123ea594692d406a7a9adda4425e40fa0967b796692d4046a11b50a5425e409a29087998692d40633ec516a7425e40c7c90e3b9d692d40),
(992, NULL, 'residential', NULL, NULL, 'way/1253846052', 0x00000000010200000003000000a7f74322a3425e4067542af235692d4083ae3374a2425e40137ea99f37692d40fb29e9bca1425e4089ea52c83a692d40),
(993, NULL, 'service', NULL, NULL, 'way/1253847345', 0x0000000001020000000200000013aa8a5f67425e401a44b5d2b5682d40c4d55cc969425e4056116e32aa682d40),
(994, NULL, 'service', NULL, NULL, 'way/1253847346', 0x000000000102000000020000006c6e96dc72425e40266b798ac1682d40266195c187425e40c3503d8853682d40),
(995, NULL, 'service', NULL, NULL, 'way/1253847347', 0x000000000102000000020000008b4347bc86425e40778c86e700682d4076e272bc82425e4025c0fa8914682d40),
(996, NULL, 'service', NULL, NULL, 'way/1253847348', 0x000000000102000000020000007a51bb5f85425e402c3c79a235682d40cc400a4389425e405aea6a3c22682d40),
(997, NULL, 'service', NULL, NULL, 'way/1253847349', 0x0000000001020000000300000076e272bc82425e4025c0fa8914682d407a51bb5f85425e402c3c79a235682d40266195c187425e40c3503d8853682d40),
(998, NULL, 'service', NULL, NULL, 'way/1253847350', 0x00000000010200000002000000304b96ee89425e4009fa0b3d62682d40266195c187425e40c3503d8853682d40),
(999, 'Jade Street', 'residential', NULL, NULL, 'way/1253855202', 0x000000000102000000040000000578c1968d425e40ef31a2fec4662d40889e94498d425e4002a9030fc2662d409a9658198d425e405152bbbabe662d405fc65e398c425e40d8e610829f662d40),
(1000, NULL, 'service', NULL, NULL, 'way/1256039187', 0x000000000102000000020000004e4700370b425e403e92376513692d40212c19b61c425e40412c9b3924692d40),
(1001, NULL, 'service', NULL, NULL, 'way/1256039188', 0x000000000102000000020000000f0f61fc34425e401186a6913b692d405b3343f435425e402e0fe37f3c692d40),
(1002, NULL, 'service', NULL, NULL, 'way/1256039189', 0x00000000010200000003000000e2fb2ce02f425e40fcf95ba736692d40c4fc265e2f425e40e02f664b56692d402a690fc52e425e406792fd987b692d40),
(1003, NULL, 'service', NULL, NULL, 'way/1256039190', 0x000000000102000000030000002a3bfda02e425e405c92037635692d40e2fb2ce02f425e40fcf95ba736692d400f0f61fc34425e401186a6913b692d40),
(1004, NULL, 'service', NULL, NULL, 'way/1256039191', 0x00000000010200000002000000c653eaed2a425e40cf5955e531692d402a3bfda02e425e405c92037635692d40),
(1005, NULL, 'service', NULL, NULL, 'way/1256041568', 0x00000000010200000002000000e926d64e39425e40d4731c89e1682d402fa2ed983a425e409721e92ee4682d40),
(1006, NULL, 'service', NULL, NULL, 'way/1256045901', 0x00000000010200000003000000eda419e65f425e4005c3b98619662d4093872aa160425e4057714ffcbd652d4069eed75361425e40259c71755b652d40),
(1007, NULL, 'service', NULL, NULL, 'way/1262014657', 0x00000000010200000002000000ec623f306c415e409d908c8b59692d40e5deb2f96e415e40317e75b059692d40),
(1008, 'Benevolence Street', 'residential', NULL, NULL, 'way/1262014658', 0x000000000102000000040000003f30ecd56c415e40eff66a91fe682d406bef535568415e40d50fa0956a692d40d718744268415e405c435f306e692d40e86c5c5a68415e402bb3525271692d40),
(1009, 'Benevolence Street', 'residential', NULL, NULL, 'way/1262014659', 0x00000000010200000008000000804754a86e415e4095a58c6e73692d40f1d187d36e415e4031b8414871692d409eea35e26e415e406e0a75a26e692d40e5deb2f96e415e40317e75b059692d405c57cc086f415e40a90df38a4c692d4015a86a276f415e40c5c9fd0e45692d405cb3f0506f415e404b08b18e3e692d401f64593071415e40c680368309692d40),
(1010, NULL, 'service', 'yes', NULL, 'way/1295359983', 0x0000000001020000000a0000003e1a9826b6495e4057659588a6362c4015fd46e0b4495e4008d9c3a8b5362c40dbabea40b1495e40a45f11b2e2362c409bf97a63ad495e40e57a809312372c406c4a6881ac495e400ccee0ef17372c402b757fabab495e40c82e07301b372c404bc2cfc99c495e40b8d38cfb45372c40daad65329c495e40fa5289fc44372c401be5aac39b495e4096653ed642372c4065ff3c0d98495e4006723f96f4362c40),
(1011, NULL, 'service', NULL, NULL, 'way/1295359986', 0x000000000102000000050000000a75a26eb1495e4039cc3c5eed352c40e29f0898af495e40c40ce8e0f4352c40b63c201aa7495e40bdd930540f362c4018aaacb797495e404651b17b3c362c4051f28f6390495e40a7fb4a3151362c40),
(1012, NULL, 'service', 'yes', NULL, 'way/1295359987', 0x00000000010200000005000000ea18a1e9b6495e408279234e82362c4073446392b6495e40942353f476362c40e29f0898af495e40c40ce8e0f4352c402a413514ad495e4033e02c25cb352c40bad0a634ac495e409f65cc13be352c40),
(1013, NULL, 'service', 'yes', NULL, 'way/1298591866', 0x0000000001020000000500000027b627edb2495e403fc16ad1a7362c40c2493f86b3495e4008bcdddca9362c40a4baca24b4495e4078dbe09fad362c40b653ce72b4495e40343c07e0b0362c4015fd46e0b4495e4008d9c3a8b5362c40),
(1014, NULL, 'service', NULL, NULL, 'way/1298591867', 0x0000000001020000000400000065ff3c0d98495e4006723f96f4362c403d61890794495e409062258ba0362c4051f28f6390495e40a7fb4a3151362c4052b648da8d495e404c44ae8a26362c40),
(1015, NULL, 'service', 'yes', NULL, 'way/1298591868', 0x000000000102000000070000000c6a0943ae495e40dd674b0cb8352c4089e4750eaf495e407da4d299c5352c400a75a26eb1495e4039cc3c5eed352c404ab4e4f1b4495e40046d173f32362c40cc1363f4b7495e40b164d87278362c401980fc5bb8495e4089038d3e8b362c403e1a9826b6495e4057659588a6362c40),
(1016, NULL, 'service', 'yes', NULL, 'way/1298591869', 0x00000000010200000004000000ea18a1e9b6495e408279234e82362c40cc1363f4b7495e40b164d87278362c40dceb4905ba495e40a975d14664362c40941fa79ebb495e402362ef6a5e362c40),
(1017, NULL, 'service', 'yes', NULL, 'way/1298591870', 0x00000000010200000003000000941fa79ebb495e402362ef6a5e362c407dc96bcaba495e403276c24b70362c401980fc5bb8495e4089038d3e8b362c40),
(1018, NULL, 'service', NULL, NULL, 'way/1298591871', 0x0000000001020000000600000044bbaf6fcc495e4088461c57c8352c4091d9b4adc1495e40057f092648362c4068d0d03fc1495e4033f735374b362c40bcbd5aa4bf495e40ad48f19650362c4034fdc863bc495e40720ba7165b362c40941fa79ebb495e402362ef6a5e362c40),
(1019, NULL, 'service', NULL, NULL, 'way/1298593180', 0x00000000010200000003000000ce305aec9b495e409de568441f362c4040efd7ae9a495e4070f2b62d25362c400cba731797495e4076ccd47f31362c40),
(1020, NULL, 'service', NULL, NULL, 'way/1298593181', 0x00000000010200000002000000aafbb6169c495e40aa9f92ce1b362c40ce305aec9b495e409de568441f362c40),
(1021, NULL, 'service', NULL, NULL, 'way/1298593182', 0x0000000001020000000200000018aaacb797495e404651b17b3c362c400cba731797495e4076ccd47f31362c40),
(1022, NULL, 'service', NULL, NULL, 'way/1298593183', 0x0000000001020000000b0000000cba731797495e4076ccd47f31362c40374591ff93495e40c6fa062637362c40af7b2b1293495e40143c2aa336362c404afbd5d292495e40697a3f2432362c40eaf29ce392495e40259ea2d92b362c406d9d6e8f94495e40be33daaa24362c40c318479b99495e40b404190115362c40a56f2dee9a495e40d8fad81313362c40f265fdc19b495e4001463c7e14362c4057e652019c495e40776a2e3718362c40aafbb6169c495e40aa9f92ce1b362c40),
(1023, NULL, 'service', NULL, NULL, 'way/1298593184', 0x00000000010200000007000000766d6fb7a4495e40f35c3a41f6352c40ac3eb214a4495e40fd265eaffa352c401135d1e7a3495e4077c0d07eff352c401db2dc2da4495e40aad5575705362c403550cf71a4495e40f139668f06362c404617e5e3a4495e40df72501d06362c406f905a72a6495e4053ca106c01362c40),
(1024, NULL, 'service', NULL, NULL, 'way/1298593185', 0x00000000010200000009000000b63c201aa7495e40bdd930540f362c406f905a72a6495e4053ca106c01362c402b306475ab495e4079c3c771f1352c405b6c49fdab495e4092cf8657ed352c40c0907af4ab495e40f3f79c05eb352c40ef1417ecab495e405a457f68e6352c404fc12b93ab495e40e0635529e2352c40c653eaedaa495e40bcd52945e1352c40766d6fb7a4495e40f35c3a41f6352c40),
(1025, NULL, 'service', NULL, NULL, 'way/1298593186', 0x0000000001020000000800000034fdc863bc495e40720ba7165b362c40a1bc8fa3b9495e40a7142aee2e362c40b9fe5d9fb9495e400e620c512a362c402a7288b8b9495e40574e8c7626362c40ed1f555ebc495e40c79860dd1d362c40b1602c1dbd495e40480fe8f120362c4046651e54bd495e40a13a0c9c22362c40bcbd5aa4bf495e40ad48f19650362c40),
(1026, NULL, 'service', NULL, NULL, 'way/1298593187', 0x0000000001020000000200000027beda519c495e4017f5a4a723372c40de640a8cab495e40ee5d83bef4362c40),
(1027, NULL, 'service', NULL, NULL, 'way/1298593188', 0x0000000001020000000f00000065283806ae495e40f06371a4d8362c40de640a8cab495e40ee5d83bef4362c40683ae05fa9495e404c101a660d372c40d3d9c9e0a8495e403f9ea74b10372c40f8e92e3fa6495e4094d9c5d919372c40cd5598639e495e4017821c9430372c408c80af8d9d495e4010a5074f32372c4074e2bc499d495e40db070f8931372c40f7c374c69c495e40541c075e2d372c4027beda519c495e4017f5a4a723372c40e0e302869b495e407f6d58ae12372c40d4f3c9e59a495e406e19cb4f05372c40d4f3c9e59a495e40930f8b6203372c4010b056ed9a495e405e72929c02372c4051b6ed209b495e40d0a9752c00372c40),
(1028, NULL, 'service', NULL, NULL, 'way/1298593189', 0x0000000001020000000200000065283806ae495e40f06371a4d8362c40e0e302869b495e407f6d58ae12372c40),
(1029, NULL, 'service', NULL, NULL, 'way/1298593190', 0x0000000001020000000800000051b6ed209b495e40d0a9752c00372c403a803452a5495e40eb538ec9e2362c403c0be7bfac495e40dae21a9fc9362c4095f48b6dad495e4028243e1cc9362c405ad93ee4ad495e404bb26900ca362c40126ff838ae495e40e5cc1bcccb362c408f311c74ae495e409ce09ba6cf362c4065283806ae495e40f06371a4d8362c40),
(1030, NULL, 'service', NULL, NULL, 'way/1298593191', 0x00000000010200000002000000be05c886a4495e40e124cd1fd3362c403a803452a5495e40eb538ec9e2362c40),
(1031, NULL, 'service', NULL, NULL, 'way/1302640126', 0x000000000102000000020000008c2c9963f9425e405d1036e103682d40d7a02fbdfd425e40f04dd36707682d40),
(1032, NULL, 'service', NULL, NULL, 'way/1303219816', 0x00000000010200000003000000b4b343577d425e4059d5dc1b8d692d4079a1ca7a7b425e408d60e3fa77692d409e66dc2f7a425e4066e2b1fa7e692d40),
(1033, NULL, 'service', 'yes', NULL, 'way/1303219817', 0x00000000010200000002000000f18fad1d7b425e40b3f803d48a692d405cbc69447a425e40ba826dc493692d40),
(1034, NULL, 'service', 'yes', NULL, 'way/1303219818', 0x0000000001020000000300000057ebc4e578425e409efc27c984692d409e66dc2f7a425e4066e2b1fa7e692d40274ae7687a425e408f2d156580692d40),
(1035, NULL, 'service', 'yes', NULL, 'way/1303219819', 0x000000000102000000040000005cbc69447a425e40ba826dc493692d4086b1e0d979425e40e38519bf95692d40751e15ff77425e40cd3e8f519e692d4005f63d8f76425e401eb57867a3692d40),
(1036, NULL, 'service', 'yes', NULL, 'way/1303219820', 0x000000000102000000030000008ec5dbef75425e40128eb4af97692d402f5ee27e76425e404fb80d5993692d4057ebc4e578425e409efc27c984692d40),
(1037, NULL, 'footway', NULL, NULL, 'way/1303220263', 0x00000000010200000003000000675eb3017d425e403e59d6a2aa6a2d401ac407767c425e4046e63686a56a2d40a90bc2267c425e40bf6ac07ba26a2d40),
(1038, 'Pablo dela Cruz Street', 'tertiary', 'no', NULL, 'way/1303221202', 0x00000000010200000003000000657094bc3a425e4046072461df662d4018601f9d3a425e40430c2a60f1662d402411757a39425e409c5c42f45a672d40),
(1039, 'Kindness Avenue', 'residential', NULL, NULL, 'way/1303723561', 0x0000000001020000000200000066f50eb743415e401a02db1c42682d40e4e8e04f43415e4023a12de752682d40),
(1040, NULL, 'residential', NULL, NULL, 'way/1303723562', 0x00000000010200000002000000a191beff45415e40b560f3bbfa6a2d40d3b4d5f640415e4015cec9e6056b2d40),
(1041, 'Efficiency Street', 'residential', NULL, NULL, 'way/1303723563', 0x000000000102000000030000009dc9ed4d42415e4096b43dd57c682d40f96871c630415e406fc273a554682d409bf6de292e415e4096687f564f682d40),
(1042, 'Faith Street', 'residential', NULL, NULL, 'way/1303723564', 0x00000000010200000008000000c16ed8b628415e4090a1630795682d40f0d533292a415e403bf3bc6598682d40f9f5436c30415e40ff959526a5682d406e5f515b34415e40364877c6ad682d40a87fff9c38415e409040cddab7682d40c35b8c263c415e40c7f2ae7ac0682d40e50ef6813f415e407651f4c0c7682d40264003a040415e40ec055559ca682d40),
(1043, NULL, 'residential', NULL, NULL, 'way/1303729484', 0x0000000001020000000300000014d852f64c415e40ff6cf5e681692d4073c982d34c415e40cb37914f7e692d40a37ecd284c415e404b0cb89d6c692d40),
(1044, NULL, 'residential', NULL, NULL, 'way/1303739642', 0x0000000001020000000200000043aa285ee5415e40ed7ce47beb6c2d40f2785a7ee0415e409352d0ed256d2d40),
(1045, 'Peter Street', 'residential', NULL, NULL, 'way/1303739845', 0x00000000010200000002000000543a58ff67415e400bfc975aa56a2d40ed93ed8d6b415e40684c778d4c6a2d40),
(1046, NULL, 'residential', NULL, NULL, 'way/1303739846', 0x00000000010200000002000000bcdfb25428415e40936a44d5546b2d409cba97a02b415e40b13b3833556b2d40),
(1047, NULL, 'service', NULL, NULL, 'way/1303739847', 0x00000000010200000002000000789961a32c415e4099c00875ec6b2d40311bae1f2c415e4016e2ec31ec6b2d40),
(1048, NULL, 'service', NULL, NULL, 'way/1303744291', 0x00000000010200000002000000bc1a457b61415e40c2dabd816e6c2d408d0c721761415e40e1fa66518e6c2d40),
(1049, 'Madre Cacao Street', 'residential', NULL, NULL, 'way/1303746987', 0x00000000010200000002000000b796c970bc415e40d97bf1457b6c2d408138b46dbd415e4069e9656f846c2d40),
(1050, 'Pablo dela Cruz Street', 'residential', NULL, NULL, 'way/1303748958', 0x000000000102000000030000008bd35ae292415e408ac0a26cdb6d2d40dee8bef792415e40c035c181da6d2d40794b283394415e40c1f00005cd6d2d40),
(1051, 'Saint James Street', 'residential', NULL, NULL, 'way/1303750795', 0x000000000102000000020000004bde4ac079415e40e2299abd226e2d406aa4a5f276415e403c58b55a166e2d40),
(1052, 'New Jersey Village', 'residential', NULL, NULL, 'way/1303752515', 0x000000000102000000060000001ca4969cc9415e40d2263dc21f6c2d40cebe9767ca415e4070de4955246c2d40150f39c7ca415e406444fd89256c2d4015826621cb415e40a0be0a95246c2d40b4cc7dcdcd415e400352ac64116c2d40ad5ffaa8d0415e402cd3d457fc6b2d40),
(1053, 'New Jersey Village', 'residential', NULL, NULL, 'way/1303752516', 0x000000000102000000020000005891d101c9415e40d41e40d01b6c2d401ca4969cc9415e40d2263dc21f6c2d40),
(1054, 'North Point Street', 'residential', 'yes', NULL, 'way/1303758241', 0x000000000102000000030000007dd34f93f4415e406c239eec666a2d40954330b3f4415e40c9a365ee6b6a2d4077fc72c1f4415e40792288f3706a2d40),
(1055, 'North Point Street', 'residential', 'yes', NULL, 'way/1303758242', 0x000000000102000000040000007d321015f4415e40abb58bc45f6a2d404dc57c2ff4415e40c8f61043616a2d4095fe147df4415e407fc2d9ad656a2d407dd34f93f4415e406c239eec666a2d40),
(1056, NULL, 'residential', 'yes', NULL, 'way/1303759995', 0x00000000010200000002000000a20e2bdcf2415e4085c7c8a3656a2d4085155dcdf0415e404e27d9ea726a2d40),
(1057, NULL, 'residential', NULL, NULL, 'way/1303759996', 0x00000000010200000002000000407edbb8ea415e40c2df2f664b6a2d4053a74de6e9415e409587e013466a2d40),
(1058, NULL, 'residential', NULL, NULL, 'way/1303759997', 0x0000000001020000000200000085155dcdf0415e404e27d9ea726a2d40a3a4d12ef0415e40992842ea766a2d40),
(1059, 'North Point Street', 'residential', 'yes', NULL, 'way/1303759998', 0x0000000001020000000300000077fc72c1f4415e40792288f3706a2d40e26d4a1ef4415e40d345afab6e6a2d40c5573b8af3415e40a5cd829a6b6a2d40),
(1060, 'Rainbow Street', 'residential', NULL, NULL, 'way/1303765446', 0x00000000010200000002000000a74de6690a425e40f2d5e99b8f6a2d40837467dc0a425e40322317f77a6a2d40),
(1061, NULL, 'service', NULL, NULL, 'way/1303773305', 0x000000000102000000030000007ecffef62b425e40453c235ba7672d40dd335c2e2c425e40a2e7bb00a0672d40248161542d425e408dbc074378672d40),
(1062, NULL, 'service', NULL, NULL, 'way/1303775590', 0x00000000010200000002000000cacffc2001425e40c991cec0c8672d40b9533a58ff415e40903e9c76e7672d40),
(1063, NULL, 'service', NULL, NULL, 'way/1303775591', 0x00000000010200000003000000fb35a33039425e404a65e5f27a672d40870cf5053e425e40e557bd0d7b672d4040602f5e3d425e408befd5d86f672d40),
(1064, 'First Street', 'residential', NULL, NULL, 'way/1303776663', 0x00000000010200000002000000bc4f9f2e1c425e409703988d29672d40c29c45941b425e40c2d375f233672d40),
(1065, NULL, 'footway', NULL, NULL, 'way/1303778961', 0x0000000001020000000700000018601f9d3a425e40430c2a60f1662d409be5b2d139425e403d4ff2d9f0662d402411757a39425e404c71b092ea662d408f519e7939425e403c122f4fe7662d404e90227c39425e40fc427eece4662d405a6cee4339425e401e4c2fd6dc662d404e93beb538425e40cead6b0fd6662d40),
(1066, NULL, 'service', 'yes', NULL, 'way/1303778962', 0x0000000001020000000400000018601f9d3a425e40430c2a60f1662d40e24c5d433a425e407bc102f3eb662d408f519e7939425e403c122f4fe7662d40241411b438425e400805a568e5662d40),
(1067, NULL, 'service', 'yes', NULL, 'way/1303778963', 0x00000000010200000005000000241411b438425e400805a568e5662d404e90227c39425e40fc427eece4662d4095e0c3db39425e4008951348e4662d405fca65483a425e405c23dd2ae3662d40657094bc3a425e4046072461df662d40),
(1068, 'Katipunan Extension', 'secondary', NULL, NULL, 'way/1303948912', 0x0000000001020000000200000045b357c455415e406284f068e36c2d4003931b4556415e40284696ccb16c2d40),
(1069, 'Katipunan Extension', 'secondary', NULL, NULL, 'way/1303948913', 0x0000000001020000000200000003931b4556415e40284696ccb16c2d40394ab95656415e4037b00bf5aa6c2d40),
(1070, 'Pablo dela Cruz Street', 'tertiary', 'no', NULL, 'way/1304698351', 0x00000000010200000003000000581b63273c425e408414973ecf662d404197152f3b425e40d3da34b6d7662d40657094bc3a425e4046072461df662d40),
(1071, 'Quirino Highway', 'primary', 'no', 'Manila-Del Monte-Garay Road', 'way/1304698352', 0x00000000010200000003000000581b63273c425e408414973ecf662d400a4735913e425e40bcd86ac5ed662d40cdafe60041425e40b57dd98706672d40),
(1072, 'Quirino Highway', 'primary', 'no', 'Manila-Del Monte-Garay Road', 'way/1304698353', 0x00000000010200000007000000cdafe60041425e40b57dd98706672d4079aeefc341425e40ed7772970e672d40535337bc45425e40fc5580ef36672d404ca4349b47425e4070777bb548672d40277dc62a4a425e40158e209562672d4015996f334b425e40935c59fd6c672d40c1070a174d425e40cb0347b87f672d40),
(1073, NULL, 'footway', NULL, NULL, 'way/1304704212', 0x00000000010200000002000000fc4dcd8a4d425e406848cb3791672d40c0a211224f425e40f0ee12e687672d40),
(1074, NULL, 'footway', NULL, NULL, 'way/1304704213', 0x00000000010200000002000000c0a211224f425e40f0ee12e687672d40c0d023464f425e406d58ae1287672d40),
(1075, NULL, 'service', NULL, NULL, 'way/1304960959', 0x0000000001020000000500000003869b421d425e4076864e7402672d403f4860bd1b425e4078b81d1a16672d40df5394a61c425e40e527d53e1d672d40fd8348861c425e400cc3ec0a22672d40bc4f9f2e1c425e409703988d29672d40),
(1076, NULL, 'service', NULL, NULL, 'way/1304960968', 0x00000000010200000002000000bfffa03ffe415e40b0b783c76d662d40d10e6e21fe415e401e262bd038662d40),
(1077, 'Quirino Highway', 'primary', 'no', 'Manila-Del Monte-Garay Road', 'way/1304960969', 0x000000000102000000040000002a3009bc38425e4040c461c499662d40f42d18013a425e40600fdc37ad662d408ea78a4e3b425e4079c5f8d5c1662d40581b63273c425e408414973ecf662d40),
(1078, NULL, 'service', NULL, NULL, 'way/1306193070', 0x000000000102000000020000001c74aecd6b425e4036188ff74f682d40281fcc376c425e40146289624d682d40),
(1079, NULL, 'service', NULL, NULL, 'way/1306193071', 0x000000000102000000020000007b794b836c425e4000a370e250682d40281fcc376c425e40146289624d682d40),
(1080, NULL, 'service', NULL, NULL, 'way/1306193072', 0x0000000001020000000200000038f6ecb94c425e40d324c2d034662d402618ce354c425e4013471e882c662d40),
(1081, NULL, 'service', NULL, NULL, 'way/1306199109', 0x00000000010200000002000000b1b508d682425e40a5654925e1672d40c9f43a9883425e40beb6c887ea672d40),
(1082, NULL, 'service', NULL, NULL, 'way/1306199110', 0x00000000010200000002000000dc54939680425e40251d8aa7c3672d409a8ddf2582425e4056e7621dd8672d40),
(1083, NULL, 'service', NULL, NULL, 'way/1306199111', 0x00000000010200000002000000c9f43a9883425e40beb6c887ea672d40aad5575785425e4047f47c1700682d40),
(1084, NULL, 'service', NULL, NULL, 'way/1306199112', 0x00000000010200000002000000246651337f425e40fbb5508df2672d40544612737f425e4064181ccaf5672d40),
(1085, NULL, 'service', NULL, NULL, 'way/1306199113', 0x00000000010200000002000000544612737f425e4064181ccaf5672d40052dc9a681425e409dfccc0f12682d40),
(1086, NULL, 'service', NULL, NULL, 'way/1306199114', 0x000000000102000000020000002c3531137b425e406b82a8fb00682d40e601d13879425e40075b913de7672d40),
(1087, 'Golden Peacock Street', 'residential', 'yes', NULL, 'way/1306199115', 0x0000000001020000000200000068a961646e425e40728c648f50672d40c089326571425e4048abb58bc4672d40),
(1088, 'Golden Peacock Street', 'residential', NULL, NULL, 'way/1306199116', 0x0000000001020000000300000067f915c671425e40eadf3f27ce672d40a29e99bb71425e4085aa3d91cc672d40c089326571425e4048abb58bc4672d40),
(1089, NULL, 'residential', 'yes', NULL, 'way/1306209136', 0x00000000010200000002000000e88711c2a3425e40be94cb9074672d40a667d542a4425e40a84d41237d672d40),
(1090, NULL, 'residential', 'yes', NULL, 'way/1306209137', 0x00000000010200000002000000f41ec253a3425e40d635ff5481672d4018e137cfa2425e40e14ad12577672d40),
(1091, NULL, 'residential', 'yes', NULL, 'way/1306209138', 0x0000000001020000000300000018e137cfa2425e40e14ad12577672d403ce8c880a2425e40cc4ef51a71672d404e53baaaa2425e400b5174136b672d40),
(1092, NULL, 'residential', NULL, NULL, 'way/1306209139', 0x000000000102000000020000004e53baaaa2425e400b5174136b672d400c4d2377a2425e40841db57867672d40),
(1093, NULL, 'residential', 'yes', NULL, 'way/1306209140', 0x000000000102000000030000004e53baaaa2425e400b5174136b672d40ac585760a3425e40f1d4230d6e672d40e88711c2a3425e40be94cb9074672d40),
(1094, NULL, 'residential', NULL, NULL, 'way/1306209141', 0x000000000102000000020000000c4d2377a2425e40841db57867672d405e503aec99425e405194957032672d40),
(1095, NULL, 'residential', NULL, NULL, 'way/1306222105', 0x000000000102000000060000003dd52137c3425e4036a33039ff682d40935e8a61bd425e40309e4143ff682d40a5283c0dbd425e4084e453b6fe682d40829774efbc425e40f0ce90e0fc682d403ad109fcbc425e4032defbc0fa682d4015d8adafbf425e40df88ee59d7682d40),
(1096, 'Belen Street', 'tertiary', NULL, NULL, 'way/1306224130', 0x00000000010200000003000000ff5c3464bc425e40a1b94e232d692d4066be839fb8425e40e3f093b42c692d4095c041d6ae425e402b2dc83b2c692d40),
(1097, NULL, 'service', NULL, NULL, 'way/1307169340', 0x0000000001020000000300000010d0d8f2a5415e406334e14d6d6b2d408dc00e52a6415e40ede41df1756b2d40518eb8b6a6415e40eb0901af856b2d40),
(1098, NULL, 'service', NULL, NULL, 'way/1307169387', 0x0000000001020000000600000065de4f32de415e40048d3e8b4a6b2d40cfd0894ee0415e4099dfc4eb556b2d40f230a30ee1415e405540eb2b596b2d40b6e74361e1415e4008477f1e596b2d4098fcaab7e1415e4050cb6a15586b2d409efefd73e2415e40ff9c386f526b2d40),
(1099, NULL, 'service', NULL, NULL, 'way/1307234968', 0x00000000010200000003000000c305eade54425e40929f43cf1c682d405caad21657425e404271112917682d407944e0a359425e40dd1e29c709682d40),
(1100, NULL, 'service', NULL, NULL, 'way/1307259333', 0x000000000102000000020000007ccd1720f6425e401ee7919ad1662d40703903c8f5425e4008139040cd662d40),
(1101, 'Quirino Highway', 'primary', 'yes', 'Manila-Del Monte-Garay Road', 'way/1307294931', 0x00000000010200000006000000ae8ed25b72425e4022cc481861692d40549ff53a73425e409b45de2868692d408ec5dbef75425e40128eb4af97692d4005f63d8f76425e401eb57867a3692d40abef575c77425e4021df4a1bb3692d40cf97288c77425e40c8b02f7ebf692d40),
(1102, 'Quirino Highway', 'primary', 'yes', 'Manila-Del Monte-Garay Road', 'way/1307294932', 0x00000000010200000005000000cf97288c77425e40c8b02f7ebf692d40766968a876425e40ea9106b7b5692d40fa36b34c75425e402642d94a9e692d404e86996c72425e40bdb32c4e6b692d40ae8ed25b72425e4022cc481861692d40),
(1103, 'Quirino Highway', 'primary', NULL, 'Manila-Del Monte-Garay Road', 'way/1307294933', 0x00000000010200000011000000ae8ed25b72425e4022cc481861692d40929b3cc06e425e40b5cb12f81e692d406fcb91df6c425e40544c4ae6fd682d40a0e238f06a425e40d42b6519e2682d4013aa8a5f67425e401a44b5d2b5682d4025bf8fb465425e4060de8893a0682d40e60c20d761425e40447122556f682d401741086d5e425e40ae5f556243682d40668bff965b425e407e9873df20682d407944e0a359425e40dd1e29c709682d40c8bf852b56425e40f2a66ca2e0672d40c8ab185355425e407a4db450d7672d40b9aef3ca50425e406a32e36da5672d40d18030a64f425e408229b97999672d40197849f74e425e40fca5457d92672d40bad16cc34d425e409ec8dd3186672d40556820964d425e4057ac866984672d40),
(1104, NULL, 'service', NULL, NULL, 'way/1307524347', 0x00000000010200000002000000e46d0091d9425e4014f131b32a692d40b4e96399d9425e402fb8301c19692d40),
(1105, NULL, 'service', NULL, NULL, 'way/1307524348', 0x00000000010200000002000000921c55f2d6425e4014f131b32a692d40bcb20b06d7425e40ab7f6b8203692d40),
(1106, NULL, 'service', NULL, NULL, 'way/1307524349', 0x00000000010200000002000000b9c5fcdcd0425e4054c0e2152d692d4065deaaebd0425e40475c5bd317692d40),
(1107, 'Diamond Avenue', 'residential', 'no', NULL, 'way/1308024305', 0x00000000010200000002000000b840dd9b3a425e4025e6fe8fb8682d4090cd9f8037425e40bde0d39cbc682d40),
(1108, NULL, 'residential', NULL, NULL, 'way/1308326070', 0x00000000010200000002000000d3212697b5425e40d4e06c29d6672d40a9fe9cddb5425e40c5591135d1672d40),
(1109, 'V. Bernardino Road', 'residential', NULL, NULL, 'way/1309879500', 0x00000000010200000004000000c2887d02a8425e40331e00cc10662d406ef717e6a9425e40e7f1c52819662d40d2ea9a7faa425e40fe9dedd11b662d404f96b5a8aa425e4092431f871c662d40),
(1110, 'Amethyst Street', 'residential', 'yes', NULL, 'way/1311380926', 0x00000000010200000002000000a9328cbbc1425e400ff6813f57662d409f967a71bd425e405641b1ba7a662d40),
(1111, 'Sapphire Street', 'residential', NULL, NULL, 'way/1311380927', 0x0000000001020000000300000000694991c6425e40a34918bc9e662d4001028c1dc3425e406215ca1d91662d409f967a71bd425e405641b1ba7a662d40),
(1112, 'Jade Street', 'residential', 'yes', NULL, 'way/1311380928', 0x000000000102000000030000004f96b5a8aa425e4092431f871c662d40e31ea6d8ac425e40802260be06662d4040fe2d5cb1425e4023bb7779df652d40),
(1113, NULL, 'service', NULL, NULL, 'way/1324344298', 0x000000000102000000030000007333373ac2495e401781b1be81352c401f01929fc3495e4020ad7b759f352c406c8198dfc4495e409c30067bb8352c40),
(1114, NULL, 'service', NULL, NULL, 'way/1338911487', 0x00000000010200000004000000aa7c748f11525e409b66cb03a20d2c40266daaee11525e40d26b58f89f0d2c408b321b6412525e4049d0042f9f0d2c40e4d6a4db12525e40f08403c69f0d2c40),
(1115, 'Quirino Highway', 'primary', NULL, 'Manila-Del Monte-Garay Road', 'way/1349521929', 0x0000000001020000000b000000666f84a07e425e406f795160a66a2d4073dbbe477d425e40c663ab70706a2d40f0726c987c425e40db08d517536a2d4014bf18807c425e40a21639fa4e6a2d403de2a1397c425e400ca4d5da456a2d40fd998b097b425e401e3f0a8d166a2d40e5153e117a425e40faf19716f5692d405dd60e9079425e40acdb453de9692d40ce1ec3be78425e40390202e7d6692d4057337c5578425e4008550f3dce692d40cf97288c77425e40c8b02f7ebf692d40),
(1116, 'Blue Bird Street', 'residential', 'yes', NULL, 'way/1349819041', 0x00000000010200000005000000c089326571425e4048abb58bc4672d4010f16a146d425e408f577b33c5672d406fb724076c425e4048abb58bc4672d4065d0bf1369425e4020387870c1672d40ca98ccc268425e408cdafd2ac0672d40),
(1117, NULL, 'busway', 'yes', NULL, 'way/1358631988', 0x00000000010200000003000000666f84a07e425e406f795160a66a2d40b48531337d425e40053f60d4a46a2d408b37328f7c425e40bcc568c29b6a2d40),
(1118, 'Quirino Highway', 'primary', 'no', 'Manila-Del Monte-Garay Road', 'way/1377595119', 0x000000000102000000030000006d6d86c036425e4097a0d0fc7b662d403dcf447d37425e400e2263ff86662d402a3009bc38425e4040c461c499662d40),
(1119, 'Quirino Highway', 'primary', 'no', 'Manila-Del Monte-Garay Road', 'way/1377595120', 0x00000000010200000002000000fd1cd59f33425e40b545e39a4c662d405cf45f3134425e40ecf7c43a55662d40),
(1120, NULL, 'footway', NULL, NULL, 'way/1377595121', 0x0000000001020000000200000043bd2a6137425e408b355ce49e662d402a3009bc38425e4040c461c499662d40),
(1121, NULL, 'footway', NULL, NULL, 'way/1377595122', 0x000000000102000000050000008a3e7a1e37425e4095b0db0cdc662d404e93beb538425e40cead6b0fd6662d40cbb4a27238425e4083f4b97fd1662d4095cc560339425e405534d6fece662d40e26366553a425e406fd003c4c9662d40);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vs_streets_crime_count`
-- (See below for the actual view)
--
CREATE TABLE `vs_streets_crime_count` (
`StreetName` varchar(255)
,`TotalCrimes` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw`
-- (See below for the actual view)
--
CREATE TABLE `vw` (
`Incident_ID` int(11)
,`Category` varchar(100)
,`Crime_Type` varchar(100)
,`Crime_Description` text
,`Date` date
,`Time` time
,`Address` varchar(255)
,`Street_Name` varchar(255)
,`Highway` varchar(100)
,`Oneway` varchar(10)
,`Witness_Name` varchar(100)
,`Witness_Age` int(11)
,`Witness_Sex` enum('Male','Female')
,`Contact_Number` varchar(20)
,`Status` enum('Active','Archived')
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_incident_report`
-- (See below for the actual view)
--
CREATE TABLE `vw_incident_report` (
`Incident_ID` int(11)
,`Category` varchar(100)
,`Crime_Type` varchar(100)
,`Crime_Description` text
,`Date` date
,`Time` time
,`Address` varchar(255)
,`Street_Name` varchar(255)
,`Highway` varchar(100)
,`Oneway` varchar(10)
,`Witness_Name` varchar(100)
,`Witness_Age` int(11)
,`Witness_Sex` enum('Male','Female')
,`Contact_Number` varchar(20)
,`Status` enum('Active','Archived')
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_street_crimes`
-- (See below for the actual view)
--
CREATE TABLE `vw_street_crimes` (
`streetId` int(11)
,`streetName` varchar(255)
,`geojson` longtext
,`categories` mediumtext
,`crimes` mediumtext
,`crimeCount` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure for view `vs_streets_crime_count`
--
DROP TABLE IF EXISTS `vs_streets_crime_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vs_streets_crime_count`  AS SELECT `s`.`Name` AS `StreetName`, count(`c`.`id`) AS `TotalCrimes` FROM ((`streets` `s` join `incident_data` `i` on(`s`.`Id` = `i`.`streetId`)) join `crime_data` `c` on(`i`.`id` = `c`.`incidentId`)) GROUP BY `s`.`Name` ORDER BY count(`c`.`id`) DESC ;

-- --------------------------------------------------------

--
-- Structure for view `vw`
--
DROP TABLE IF EXISTS `vw`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw`  AS SELECT `i`.`id` AS `Incident_ID`, `c`.`category` AS `Category`, `c`.`crimeType` AS `Crime_Type`, `c`.`crimeDescription` AS `Crime_Description`, `i`.`date` AS `Date`, `i`.`time` AS `Time`, `i`.`address` AS `Address`, `s`.`Name` AS `Street_Name`, `s`.`Highway` AS `Highway`, `s`.`Oneway` AS `Oneway`, `i`.`witnessName` AS `Witness_Name`, `i`.`witnessAge` AS `Witness_Age`, `i`.`witnessSex` AS `Witness_Sex`, `i`.`contactNumber` AS `Contact_Number`, `c`.`status` AS `Status` FROM ((`incident_data` `i` join `crime_data` `c` on(`i`.`id` = `c`.`incidentId`)) join `streets` `s` on(`i`.`streetId` = `s`.`Id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_incident_report`
--
DROP TABLE IF EXISTS `vw_incident_report`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_incident_report`  AS SELECT `i`.`id` AS `Incident_ID`, `c`.`category` AS `Category`, `c`.`crimeType` AS `Crime_Type`, `c`.`crimeDescription` AS `Crime_Description`, `i`.`date` AS `Date`, `i`.`time` AS `Time`, `i`.`address` AS `Address`, `s`.`Name` AS `Street_Name`, `s`.`Highway` AS `Highway`, `s`.`Oneway` AS `Oneway`, `i`.`witnessName` AS `Witness_Name`, `i`.`witnessAge` AS `Witness_Age`, `i`.`witnessSex` AS `Witness_Sex`, `i`.`contactNumber` AS `Contact_Number`, `c`.`status` AS `Status` FROM ((`incident_data` `i` join `crime_data` `c` on(`i`.`id` = `c`.`incidentId`)) join `streets` `s` on(`i`.`streetId` = `s`.`Id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_street_crimes`
--
DROP TABLE IF EXISTS `vw_street_crimes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_street_crimes`  AS SELECT `s`.`Id` AS `streetId`, `s`.`Name` AS `streetName`, st_asgeojson(`s`.`Geometry`) AS `geojson`, group_concat(distinct `c`.`category` order by `c`.`category` ASC separator ', ') AS `categories`, group_concat(distinct `c`.`crimeType` order by `c`.`crimeType` ASC separator ', ') AS `crimes`, count(`c`.`id`) AS `crimeCount` FROM ((`streets` `s` join `incident_data` `i` on(`s`.`Id` = `i`.`streetId`)) join `crime_data` `c` on(`i`.`id` = `c`.`incidentId`)) WHERE `c`.`category` is not null AND `c`.`crimeType` is not null GROUP BY `s`.`Id` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `crime_data`
--
ALTER TABLE `crime_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `incidentId` (`incidentId`);

--
-- Indexes for table `incident_data`
--
ALTER TABLE `incident_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `streetId` (`streetId`);

--
-- Indexes for table `streets`
--
ALTER TABLE `streets`
  ADD PRIMARY KEY (`Id`),
  ADD SPATIAL KEY `Geometry` (`Geometry`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `crime_data`
--
ALTER TABLE `crime_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1066;

--
-- AUTO_INCREMENT for table `incident_data`
--
ALTER TABLE `incident_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1066;

--
-- AUTO_INCREMENT for table `streets`
--
ALTER TABLE `streets`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1122;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `crime_data`
--
ALTER TABLE `crime_data`
  ADD CONSTRAINT `crime_data_ibfk_1` FOREIGN KEY (`incidentId`) REFERENCES `incident_data` (`id`);

--
-- Constraints for table `incident_data`
--
ALTER TABLE `incident_data`
  ADD CONSTRAINT `incident_data_ibfk_1` FOREIGN KEY (`streetId`) REFERENCES `streets` (`Id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
