<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

/*
    CDW controls
    Date Created: October 5, 2021
*/

$currDir = dirname(__FILE__);

require_once $currDir . '/../globals.php';
require_once $currDir . '/../db_cdw_sqlsrv.php';
require_once $currDir . '/../Email.php';
require_once $currDir . '/../form.php';
require_once $currDir . '/../FormWorkflow.php';
require_once $currDir . '/../sources/Workflow.php';
if (!class_exists('XSSHelpers')) {
    require_once dirname(__FILE__) . '/../../libs/php-commons/XSSHelpers.php';
}
if (!class_exists('Orgchart\Config'))
{
    require_once '../' . Config::$orgchartPath . '/config.php';
    require_once '../' . Config::$orgchartPath . '/sources/Login.php';
    require_once '../' . Config::$orgchartPath . '/sources/Employee.php';
 }

class CDW
{
    public $siteRoot = '';

    private $db;
    private $db_nexus;
    private $db_cdw;

    private $login;
    private $employee;
    private $form;
    private $formWork;

    public function __construct($db, $login)
    {
        $this->db = $db;
        $this->login = $login;
        $config = new Config();
        $this->db_nexus = new DB($config->phonedbHost, $config->phonedbUser, $config->phonedbPass, $config->phonedbName);

        $this->employee = new Orgchart\Employee($this->db_nexus, $login);
        $this->form = new Form($db, $login);
        $this->formWork = new FormWorkflow($db, $login, 0);

        $this->siteRoot = "https://" . HTTP_HOST . dirname($_SERVER['REQUEST_URI']) . '/';
    }

    public function getVaccineStatus($userID) {
        $resEmp = $this->employee->lookupDelLogin($userID);
        $empEmail = $resEmp[0]['email'];

        if (filter_var($empEmail, \FILTER_VALIDATE_EMAIL) === false) {
            return 'Invalid Email';
        }

        $strVars = array(
            ':employeeEmail' => $empEmail
        );
        $strSQL = "SELECT [HREmpID],[EmployeeEmail],[EmployeeADAccountName],[VaccineName],[VaccineStatus],".
            "[HRType],[ComplianceType],[HCP],[NonComplyReason],[VaccineInfoID],[LastModifiedDate] ".
            "FROM [Model].[VaccineCompliance] ".
            "WHERE [EmployeeEmail] = :employeeEmail";
        $this->db_cdw = new DB_CDW('BISL_OHRS');
        $res = $this->db_cdw->prepared_query($strSQL, $strVars);

        $res[0] = array_merge($res[0], $resEmp[0]);

        if (count($res) > 0) {
            return $res[0];
        } else {
            return 'No User Found';
        }
    }

    public function vaccineStatusEmail($userID = null){
        if (!$this->login->checkGroup(1))
        {
            return 'Admin Only';
        }
        if ($userID === null)
        {
            return 'Invalid userID';
        }
        $this->complianceROI($userID);

        return 1;
    }

    public function vaccineInfoError($recordID, $userID) {
        $strVars = array(':recordID' => $recordID,
                         ':userID' => $userID);
        $strSQL = "INSERT INTO vaccine_error (recordID, userID) VALUES (:recordID, :userID) ".
                    "ON DUPLICATE KEY UPDATE recordID=:recordID, userID=:userID";
        $this->db->prepared_query($strSQL, $strVars);

        return 'Error Reported';
    }

    public function vaccineBulkExport($isLocal = false) {
	    if (!$this->login->checkGroup(1))
        {
            return 'Admin Only';
        }
	    $strSQL = "SELECT recordID FROM records WHERE submitted > 0 AND deleted = 0";
	    $res = $this->db->query($strSQL);
	    foreach ($res as $tmp) {
            if ($isLocal === false) {
                $this->modifyVaccine($tmp['recordID']);
            } else {
                $this->modifyLocalVaccine($tmp['recordID']);
            }
	    }

	    return 1;
    }

    public function complianceROI($userID) {
        $res = $this->getVaccineStatus($userID);

        $strVars = array(':recordID' => $res['VaccineInfoID']);
        $strSQL = "SELECT stepID, submitted FROM records_workflow_state LEFT JOIN records using (recordID) ".
                    "WHERE recordID = :recordID AND stepID IN (20, 22) AND deleted = 0";
        $res2 = $this->db->prepared_query($strSQL, $strVars);


        $res = array_merge($res, $res2[0]);

        $sendEmail = false;
        $sendAudit = false;
        $sendNotFound = false;

        // Process Paths
        if (in_array($res['stepID'], array(22, 20))) {
            $this->formWork->initRecordID($res['VaccineInfoID']);
            switch ($res['stepID']) {
                // Path 1 Holding
                case 22:
                    switch (strtolower($res['ComplianceType'])) {
                        case "compliant":
                            $this->formWork->setStep(23, true, 'Moved by CDW');
                            $sendEmail = true;
                            break;
                        case "not found":
                            $this->formWork->setStep(31, true, 'Moved by CDW');
                            $sendNotFound = true;
                            break;
                    }
                    break;
                // Path 2 Holding
                case 20:
                    switch (strtolower($res['ComplianceType'])) {
                        case "compliant":
                            $this->formWork->setStep(25, true, 'Moved by CDW');
                            $sendEmail = true;
                            break;
                        case "under review":
                            $this->formWork->setStep(15, true, 'Moved by CDW');
                            $sendAudit = true;
                            break;
                    }
                    break;
            }
        }

        $strVars = array(':vaccineInfoID' => $res['VaccineInfoID']);
        $strSQL = "SELECT data from data WHERE indicatorID = 48 AND recordID = :vaccineInfoID";
        $result = $this->db->prepared_query($strSQL, $strVars);

        $supervisor = $this->employee->lookupDelEmpUID($result[0]['data']);

        if ($sendEmail) {
            $email = new Email();
            $email->setSender("noreply@leaf.va.gov");
            $email->setSubject("Vaccine Mandate Compliance Information");
            $strContent = '<p>'.htmlspecialchars($res['firstName'], ENT_QUOTES).' '.htmlspecialchars($res['lastName'], ENT_QUOTES).',</p> '.
                '<p>Thank you for completing the Vaccination Status form in LEAF on '.date("F j, Y",$res['submitted']).'.</p>'.
                '<p>This email is to notify you that your vaccine status has changed to <strong>Compliant</strong>. '.
                'Please keep this email for your records.</p>';

            $email->setBody($strContent);
            $email->addRecipient($res['EmployeeEmail']);
            $email->sendMail();

            return 1;
        }

        if ($sendAudit) {
            $emailAud = new Email();
            $emailAud->setSender("noreply@leaf.va.gov");
            $emailAud->setSubject("Vaccine Mandate Supervisor Approval Information");
            $strContent = "<p>".htmlspecialchars($res['firstName'], ENT_QUOTES)." ".htmlspecialchars($res['lastName'], ENT_QUOTES).",</p>".
                "<p>As part of the COVID Vaccine mandate reporting process, you will be asked to review your employees' ".
                "randomly selected LEAF submissions.  One of your employees' records have been randomly selected.  ".
                "You can review the submitted vaccine information and compare it to the uploaded vaccine documentation ".
                "<a href='https://leaf.va.gov/NATIONAL/101/vaccination_data_reporting' target='_blank'>here</a>. ".
                "Once you review the records to ensure that all the information matches, you will have three choices:</p> ".
                "<ul><li>Approved - Everything looks good</li>".
                "<li>Returning - Vaccine documentation does not match submitted information</li>".
                "<li>Returning - Employee did not enter required information</li></ul>".
                "<p>Please review to ensure your employee can meet the deadline for submitting vaccination information in LEAF on time</p>";

            $emailAud->setBody($strContent);
            $emailAud->addCcBcc($res['EmployeeEmail']);
            $emailAud->addRecipient($supervisor[0]['email']);
            $emailAud->sendMail();

            return 1;
        }

        if ($sendNotFound) {
            $emailNF = new Email();
            $emailNF->setSender("noreply@leaf.va.gov");
            $emailNF->setSubject("ACTION NEEDED - Vaccine Mandate Compliance");
            $strContent = "<p>".htmlspecialchars($res['firstName'], ENT_QUOTES)." ".htmlspecialchars($res['lastName'], ENT_QUOTES).",</p>".
                "<p>You are receiving this email because you submitted a request in ".
                "Light Electronic Action Framework (LEAF) to have VHA pull your vaccine records to show proof ".
                "of your vaccination at a VHA facility. We tried, but <strong><em>unfortunately we were not able to access ".
                "your vaccine records</em></strong>. This could be a technical issue in attempting to link your records to LEAF. ".
                "It could also mean that VA has no record of your vaccine.</p>".
                "<p>We are sorry to inconvenience you, but you will need to either:</p>".
                "<ul><li>Work with the Occupational Health office where you got your vaccine to update your ".
                "information and fix the information discrepancy, OR</li>".
                "<li>Go back into LEAF and upload a copy of your vaccine card</li></ul>".
                "<p>Below is guidance on getting a copy of your vaccination card if you no longer have your card, ".
                "and instructions on how to update your records in LEAF.</p>".
                "<p><strong>How do I get a copy of my vaccination card if I lost mine?</strong><br />".
                "Please contact your local Occupational Health office to ask for a copy of your card. If you ".
                "are a Veteran (VHA patient), and Occupational Health does not have a record in the ".
                "Occupational Health Records System (OHRS), your records may be in your Veteran's patient records; ".
                "your Occupational Health office can copy it over to your employee's records and share a copy with you.</p>".
                "<p><strong>How do I upload a copy of my vaccine card?</strong><br />".
                "To upload your vaccine card, please:</p>".
                "<ul><li>Go into <a href='https://leaf.va.gov/NATIONAL/101/vaccination_data_reporting' target='_blank'>LEAF</a></li>".
                "<li>Click on the \"Review or Update your record\"<br /> ".
                "<img src='https://leaf.va.gov/NATIONAL/101/vaccination_data_reporting/files/review_update_record.jpg' ".
                "alt='Review or Update Your Record Button' /><br />&nbsp;</li>".
                "<li>Click on the \"Reset and Start over\" button to the left side of the screen. When asked if you ".
                "are sure you want to start over, click \"Yes\".<br />".
                "<img src='https://leaf.va.gov/NATIONAL/101/vaccination_data_reporting/files/reset_start_over.jpg' ".
                "alt='Reset and Start Over Button' /><br />&nbsp;</li>".
                "<li>Click on \"I have been vaccinated in VHA and want to upload the records myself\"<br /> ".
                "<img src='https://leaf.va.gov/NATIONAL/101/vaccination_data_reporting/files/path_1_v2.jpg' ".
                "alt='I Have Been Vaccinated by the VHA and want to upload my vaccination records myself' /><br />&nbsp;</li>".
                "<li>Complete all the information and submit</li></ul>".
                "<p><strong>Note:</strong> To ensure your supervisor is aware you attempted to comply with the ".
                "deadline, we are copying your supervisor on this email.</p>".
                "<p>Again, we are sorry for the inconvenience, and appreciate your help in uploading the information ".
                "needed as soon as possible.</p>";

            $emailNF->setBody($strContent);
            $emailNF->addRecipient($res['EmployeeEmail']);
            $emailNF->addCcBcc($supervisor[0]['email']);
            $emailNF->sendMail();

            return 1;
        }

        return 0;
    }

    public function modifyVaccine($recordID = null, $isLocal = 'true') {
        if ($recordID === null) {
            return 'No Record Found';
        }
	    if ($_POST['CSRFToken'] != $_SESSION['CSRFToken'])
        {
            return 'Invalid CSRFToken';
        }
        $indicatorIDs = '242,261,42,262,48,195,183,187,184,188,104,265,210,282,106';
        $strVars = array(
            ':recordID' => $recordID
        );
        $strSQL = "SELECT rec.recordID, rec.userID, dt.data, dt.timestamp, indi.indicatorID, rec.submitted ".
                "FROM data AS dt ".
                    "INNER JOIN indicators AS indi ON indi.indicatorID = dt.indicatorID ".
                    "INNER JOIN categories AS cate ON indi.categoryID = cate.categoryID ".
                    "INNER JOIN records AS rec ON rec.recordID = dt.recordID ".
                "WHERE ".
                    "cate.disabled = 0 ".
                    "AND indi.disabled = 0 ".
                    "AND rec.submitted > 0 ".
                    "AND dt.indicatorID IN (". $indicatorIDs .") ".
                    "AND rec.deleted = 0 ".
                    "AND rec.recordID = :recordID ".
                "ORDER BY ".
                    "recordID, timestamp DESC";

        $res = $this->db->prepared_query($strSQL, $strVars);

        $packet = array(
            'vaccineInfoID' => $recordID,
            'submittedDate' => date("Y-m-d H:i:s",$res[0]['submitted']),
            'employeeEmail' => null,
            'employeeAD' => null,
            'supervisorEmail' => null,
            'supervisorAD' => null,
            'vaccinePathway' => null,
            'vaccineName' => null,
            'doseOneDate' => null,
            'doseOneLocation' => null,
            'doseTwoDate' => null,
            'doseTwoLocation' => null,
            'vaccineDocType' => null,
            'exceptionType' => null,
            'perjuryStatus' => 0,
            'releaseStatus' => 0,
            'vaccineDocDate' => null,
            'lastModified' => date("Y-m-d H:i:s",$res[0]['timestamp']),
            'dataUploadDT' => date("Y-m-d H:i:s")
        );

        $resUserEmail = $this->employee->lookupDelLogin($res[0]['userID']);
        $packet['employeeEmail'] = $resUserEmail[0]['email'];
        $packet['employeeAD'] = $res[0]['userID'];

        if ($packet['employeeEmail'] === null || $packet['employeeEmail'] === '') {
            $this->vaccineInfoError($recordID,$res[0]['userID']);

            return 'Email not found';
        }

	    $forms = "'form_2e22e', 'form_2e050', 'form_6958f'";
        $strVars = array(
            ':recordID' => $recordID);
        $strSQL = "SELECT categoryID FROM category_count ".
            "WHERE recordID = :recordID ".
            "AND categoryID IN (". $forms .")";
        $resPath = $this->db->prepared_query($strSQL, $strVars);

        if ($resPath[0]['categoryID'] === 'form_2e22e') {
            $packet['vaccinePathway'] = 'Vaccinated by VHA - Import Records';
        } elseif ($resPath[0]['categoryID'] === 'form_2e050') {
            $packet['vaccinePathway'] = 'Vaccinated by VHA/Outside - Manual Records';
        } elseif ($resPath[0]['categoryID'] === 'form_6958f') {
            $packet['vaccinePathway'] = 'Exemption';
        }

        $indicators = array(
            48  => 'Supervisor',
            104 => 'vaccineDocType',
            106 => 'vaccineDocDate', // datetime
            183 => 'doseOneDate',
            184 => 'doseTwoDate',
            187 => 'doseOneLocation',
            188 => 'doseTwoLocation',
            195 => 'vaccineName',
            210 => 'perjuryStatus', // not null = 1 else 0
            242 => 'releaseStatus', // not null = 1 else 0
            265 => 'exceptionType'
        );
        foreach ($res as $tmp) {
            switch ($tmp['indicatorID']) {
                case 48:
                    $resSuper = $this->employee->lookupDelEmpUID($tmp['data']);
                    $packet['supervisorEmail'] = $resSuper[0]['email'];
                    $packet['supervisorAD'] = $resSuper[0]['userName'];
                    if ($packet['supervisorEmail'] === null || $packet['supervisorEmail'] === '') {
                        $this->vaccineInfoError($recordID, $resSuper[0]['userName']);
                    }
                    break;
                case 106:
                    $indicatorID = $tmp['indicatorID'];
                    $packet[$indicators[$indicatorID]] = date("Y-m-d H:i:s",$tmp['timestamp']);
                    break;
                case 210:
                case 242:
                    $indicatorID = $tmp['indicatorID'];
                    if ($tmp['data'] === 'SIGN') {
                        $packet[$indicators[$indicatorID]] = 1;
                    } else {
                        $packet[$indicators[$indicatorID]] = 0;
                    }
                    break;
                default:
                    $indicatorID = $tmp['indicatorID'];
                    $packet[$indicators[$indicatorID]] = $tmp['data'];
                    break;
            }
        }
        $strVars = array(':vaccineInfoID' => $packet['vaccineInfoID'],
            ':employeeEmail' => $packet['employeeEmail'],
            ':employeeAD' => $packet['employeeAD'],
            ':supervisorEmail' => $packet['supervisorEmail'],
            ':supervisorAD' => $packet['supervisorAD'],
            ':vaccinePathway' => $packet['vaccinePathway'],
            ':vaccineName' => $packet['vaccineName'],
            ':doseOneDate' => $packet['doseOneDate'],
            ':doseOneLocation' => $packet['doseOneLocation'],
            ':doseTwoDate' => $packet['doseTwoDate'],
            ':doseTwoLocation' => $packet['doseTwoLocation'],
            ':vaccineDocType' => $packet['vaccineDocType'],
            ':exceptionType' => $packet['exceptionType'],
            ':perjuryStatus' => $packet['perjuryStatus'],
            ':releaseStatus' => $packet['releaseStatus'],
            ':vaccineDocDate' => $packet['vaccineDocDate'],
            ':submittedDate' => $packet['submittedDate'],
            ':lastModified' => $packet['lastModified'],
	        ':dataUploadDT' => $packet['dataUploadDT']);
        if ($isLocal === 'false') {
            $strSQL = "DECLARE @vaccineInfoID int = :vaccineInfoID,@employeeEmail varchar(255) = :employeeEmail,@employeeAD varchar(255) = :employeeAD," .
                            "@supervisorEmail varchar(255) = :supervisorEmail,@supervisorAD varchar(255) = :supervisorAD,@vaccinePathway varchar(255) = :vaccinePathway," .
                            "@vaccineName varchar(255) = :vaccineName,@doseOneDate varchar(255) = :doseOneDate,@doseOneLocation varchar(255) = :doseOneLocation,@doseTwoDate varchar(255) = :doseTwoDate," .
                            "@doseTwoLocation varchar(255) = :doseTwoLocation,@vaccineDocType varchar(255) = :vaccineDocType,@exceptionType varchar(255) = :exceptionType," .
                            "@perjuryStatus varchar(255) = :perjuryStatus,@releaseStatus varchar(255) = :releaseStatus,@vaccineDocDate varchar(255) = :vaccineDocDate," .
                            "@submittedDate varchar(255) =:submittedDate,@lastModified varchar(255) = :lastModified,@dataUploadDT varchar(255) = :dataUploadDT " .
                        "IF EXISTS (SELECT [PK_VaccineInfo] FROM [Import].[LEAF_Vaccine_Info] WHERE [PK_VaccineInfo] = @vaccineInfoID) " .
                        "UPDATE [Import].[LEAF_Vaccine_Info] " .
                        "SET [PK_VaccineInfo] = @vaccineInfoID,[employeeEmail] = @employeeEmail,[employeeAD] = @employeeAD," .
                            "[supervisorEmail] = @supervisorEmail,[supervisorAD] = @supervisorAD,[vaccinePathway] = @vaccinePathway," .
                            "[vaccineName] = @vaccineName,[doseOneDate] = @doseOneDate,[doseOneLocation] = @doseOneLocation," .
                            "[doseTwoDate] = @doseTwoDate,[doseTwoLocation] = @doseTwoLocation,[vaccineDocType] = @vaccineDocType," .
                            "[exceptionType] = @exceptionType,[perjuryStatus] = @perjuryStatus,[releaseStatus] = @releaseStatus," .
                            "[vaccineDocDate] = @vaccineDocDate,[submittedDate] = @submittedDate,[lastModified] = @lastModified," .
                            "[dataUploadDT] = @dataUploadDT " .
                        "WHERE [PK_VaccineInfo] = @vaccineInfoID " .
                        "ELSE " .
                        "INSERT INTO [Import].[LEAF_Vaccine_Info] ([PK_VaccineInfo],[employeeEmail],[employeeAD], [supervisorEmail]," .
                            "[supervisorAD],[vaccinePathway],[vaccineName],[doseOneDate],[doseOneLocation],[doseTwoDate], [doseTwoLocation]," .
                            "[vaccineDocType],[exceptionType],[perjuryStatus],[releaseStatus],[vaccineDocDate],[submittedDate], [lastModified]," .
                            "[dataUploadDT]) VALUES (@vaccineInfoID,@employeeEmail,@employeeAD," .
                            "@supervisorEmail,@supervisorAD,@vaccinePathway,@vaccineName,@doseOneDate," .
                            "@doseOneLocation,@doseTwoDate,@doseTwoLocation,@vaccineDocType,@exceptionType," .
                            "@perjuryStatus,@releaseStatus,@vaccineDocDate,@submittedDate,@lastModified,@dataUploadDT)";
            $this->db_cdw = new DB_CDW('BISL_OHRS');
            $this->db_cdw->prepared_query($strSQL, $strVars);

            /** TODO: Waiting for CDW to update Stored Procedure for individual EmpEmail input
            $strVars = array(':employeeEmail' => $packet['employeeEmail']);
            $strSQL = "EXEC [ETL].[Post_LEAF_Import]";
            $res = $this->db_cdw->query($strSQL);*/
        } else {
            $strSQL = "INSERT INTO vaccine_info (vaccineInfoID, employeeEmail, employeeAD, supervisorEmail, supervisorAD, vaccinePathway, ".
                            "vaccineName, doseOneDate, doseOneLocation, doseTwoDate, doseTwoLocation, vaccineDocType, exceptionType, ".
                            "perjuryStatus, releaseStatus, vaccineDocDate, submittedDate, lastModified, dataUploadDT) ".
                        "VALUES (:vaccineInfoID, :employeeEmail, :employeeAD, :supervisorEmail, :supervisorAD, :vaccinePathway, ".
                            ":vaccineName, :doseOneDate, :doseOneLocation, :doseTwoDate, :doseTwoLocation, :vaccineDocType, :exceptionType, ".
                            ":perjuryStatus, :releaseStatus, :vaccineDocDate, :submittedDate, :lastModified, :dataUploadDT) ".
                        "ON DUPLICATE KEY UPDATE employeeEmail=:employeeEmail, employeeAD=:employeeAD, supervisorEmail=:supervisorEmail, ".
                            "supervisorAD=:supervisorAD, vaccinePathway=:vaccinePathway, vaccineName=:vaccineName, ".
                            "doseOneDate=:doseOneDate, doseOneLocation=:doseOneLocation, doseTwoDate=:doseTwoDate, ".
                            "doseTwoLocation=:doseTwoLocation, vaccineDocType=:vaccineDocType, exceptionType=:exceptionType, ".
                            "perjuryStatus=:perjuryStatus, releaseStatus=:releaseStatus, vaccineDocDate=:vaccineDocDate, ".
                            "submittedDate=:submittedDate, lastModified=:lastModified, dataUploadDT=:dataUploadDT";
            $this->db->prepared_query($strSQL, $strVars);
        }

        //$this->complianceROI($packet['employeeAD']);

        return 1;
    }

    public function deleteVaccine($recordID = null, $isLocal = 'true') {
	if ($_POST['CSRFToken'] != $_SESSION['CSRFToken'])
        {
            return 'Invalid Token.';
        }
        if ($recordID != null) {
            $strVars = array(
                ':vaccineInfoID' => $recordID
            );
            if ($isLocal === 'false') {
                $strSQL = "DELETE FROM [Import].[LEAF_Vaccine_Info] WHERE [PK_VaccineInfo] = :vaccineInfoID";
                $this->db_cdw = new DB_CDW('BISL_OHRS');
                $this->db_cdw->prepared_query($strSQL, $strVars);
            } else {
                $strSQL = "DELETE FROM vaccine_info WHERE vaccineInfoID = :vaccineInfoID";
                $this->db->prepared_query($strSQL, $strVars);
            }

            return 1;
        } else {
            return 'Record not Found';
        }
    }
	
    public function revokeROI($recordID = null, $isLocal = 'true') {
	if (!$_POST['releaseStatus']) {
	    return 'Release Status not Found';
	}
	if ($recordID != null) {
            $strVars = array(
                ':vaccineInfoID' => $recordID,
		':releaseStatus' => $_POST['releaseStatus']
            );
            if ($isLocal === 'false') {
                $strSQL = "UPDATE [Import].[LEAF_Vaccine_Info] SET [releaseStatus] = :releaseStatus WHERE [PK_VaccineInfo] = :vaccineInfoID";
                $this->db_cdw = new DB_CDW('BISL_OHRS');
                $this->db_cdw->prepared_query($strSQL, $strVars);
            } else {
                $strSQL = "UPDATE vaccine_info SET releaseStatus = :releaseStatus WHERE vaccineInfoID = :vaccineInfoID";
                $this->db->prepared_query($strSQL, $strVars);
            }

            return 1;
        } else {
            return 'Record not Found';
        }
    }
}
