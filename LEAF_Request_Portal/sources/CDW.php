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

    public function __construct($db, $login)
    {
        $this->db = $db;
        $this->login = $login;
        $this->db_cdw = new DB_CDW('BISL_OHRS');
        $config = new Config();
        $this->db_nexus = new DB($config->phonedbHost, $config->phonedbUser, $config->phonedbPass, $config->phonedbName);

        $this->employee = new Orgchart\Employee($this->db_nexus, $login);

        $this->siteRoot = "https://" . HTTP_HOST . dirname($_SERVER['REQUEST_URI']) . '/';
    }

    public function getVaccineStatus() {
        $empEmail = XSSHelpers::xssafe($_POST["employee_email"]);
        if (filter_var($empEmail, \FILTER_VALIDATE_EMAIL) === false) {
            return 'Invalid Email';
        }

        $strVars = array(
            ':employeeEmail' => $empEmail
        );
        $strSQL = "DECLARE @employeeEmail varchar(255) = :employeeEmail ".
            "SELECT [HREmpID],[EmployeeEmail],[EmployeeADAccountName],[VaccineDateDose1],".
            "[VaccineDateDose2],[VaccineName],[VaccineStatus],[VaccineDose1Location],[VaccineDose2Location],".
            "[Dose1LocationName],[Dose2LocationName],[HRType],[ComplianceType],[HCP],[SourceLastModifiedDate],".
            "[SourceDataUploadDate],[NonComplyReason],[VaccineInfoID],[VaccinePathway],[LastModifiedDate] ".
            "FROM [BISL_OHRS].[Model].[VaccineCompliance] ".
            "WHERE [EmployeeEmail] = @employeeEmail";
        $res = $this->db_cdw->prepared_query($strSQL, $strVars);

        if (count($res) > 0) {
            return $res[0];
        } else {
            return "No User Found";
        }
    }

    public function modifyVaccine($recordID = null) {
        if ($recordID === null) {
            return "No Record Found";
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
                    "recordID, indicatorID";

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
            'lastModified' => null,
            'dataUploadDT' => null
        );

        $resUserEmail = $this->employee->lookupDelLogin($res[0]['userID']);
        $packet['employeeEmail'] = $resUserEmail[0]['email'];
        $packet['employeeAD'] = $res[0]['userID'];

        $vars = array(
            ':recordID' => $recordID,
            ':forms' => array('form_2e22e', 'form_2e050', 'form_6958f'));
        $strSQL = "SELECT categoryID FROM category_count ".
            "WHERE recordID = :recordID ".
            "AND categoryID IN :forms";
        $resPath = $this->db->prepared_query($strSQL, $vars);

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

        $vars = array(':vaccineInfoID' => $packet['vaccineInfoID'],
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
            ':lastModified' => time());
        $strSQL = "DECLARE @vaccineInfoID int = :vaccineInfoID,@employeeEmail varchar(255) = :employeeEmail,@employeeAD varchar(255) = :employeeAD,".
	            "@supervisorEmail varchar(255) = :supervisorEmail,@supervisorAD varchar(255) = :supervisorAD,@vaccinePathway varchar(255) = :vaccinePathway,".
	            "@vaccineName varchar(255) = :vaccineName,@doseOneDate varchar(255) = :doseOneDate,@doseOneLocation varchar(255) = :doseOneLocation,@doseTwoDate varchar(255) = :doseTwoDate,".
	            "@doseTwoLocation varchar(255) = :doseTwoLocation,@vaccineDocType varchar(255) = :vaccineDocType,@exceptionType varchar(255) = :exceptionType,".
	            "@perjuryStatus varchar(255) = :perjuryStatus,@releaseStatus varchar(255) = :releaseStatus,@vaccineDocDate varchar(255) = :vaccineDocDate,".
	            "@submittedDate varchar(255) =:submittedDate,@lastModified varchar(255) = :lastModified,@dataUploadDT varchar(255) = :dataUploadDT ".
	        "IF EXISTS (SELECT [PK_VaccineInfo] FROM [Import].[LEAF_Vaccine_Info] WHERE [PK_VaccineInfo] = @vaccineInfoID) ".
		        "UPDATE [Import].[LEAF_Vaccine_Info] ".
		        "SET [PK_VaccineInfo] = @vaccineInfoID,[employeeEmail] = @employeeEmail,[employeeAD] = @employeeAD,".
		        "[supervisorEmail] = @supervisorEmail,[supervisorAD] = @supervisorAD,[vaccinePathway] = @vaccinePathway,".
		        "[vaccineName] = @vaccineName,[doseOneDate] = @doseOneDate,[doseOneLocation] = @doseOneLocation,".
		        "[doseTwoDate] = @doseTwoDate,[doseTwoLocation] = @doseTwoLocation,[vaccineDocType] = @vaccineDocType,".
		        "[exceptionType] = @exceptionType,[perjuryStatus] = @perjuryStatus,[releaseStatus] = @releaseStatus,".
		        "[vaccineDocDate] = @vaccineDocDate,[submittedDate] = @submittedDate,[lastModified] = @lastModified,".
		        "[dataUploadDT] = @dataUploadDT ".
		        "WHERE [PK_VaccineInfo] = @vaccineInfoID ".
	        "ELSE ".
		        "INSERT INTO [Import].[LEAF_Vaccine_Info] ([PK_VaccineInfo],[employeeEmail],[employeeAD], [supervisorEmail],".
		        "[supervisorAD],[vaccinePathway],[vaccineName],[doseOneDate],[doseOneLocation],[doseTwoDate], [doseTwoLocation],".
		        "[vaccineDocType],[exceptionType],[perjuryStatus],[releaseStatus],[vaccineDocDate],[submittedDate], [lastModified],".
		        "[dataUploadDT]) VALUES (@vaccineInfoID,@employeeEmail,@employeeAD,".
		        "@supervisorEmail,@supervisorAD,@vaccinePathway,@vaccineName,@doseOneDate,".
		        "@doseOneLocation,@doseTwoDate,@doseTwoLocation,@vaccineDocType,@exceptionType,".
		        "@perjuryStatus,@releaseStatus,@vaccineDocDate,@submittedDate,@lastModified,@dataUploadDT)";
        $this->db_cdw->prepared_query($strSQL, $vars);
    }

    public function deleteVaccine($recordID = null) {
        if ($recordID != null) {
            $strVars = array(
                ':vaccineInfoID' => $recordID
            );
            $strSQL = 'DELETE FROM [BISL_OHRS].[Import].[LEAF_Vaccine_Info] WHERE [PK_VaccineInfo] = :vaccineInfoID';
            $res = $this->db_cdw->prepared_query($strSQL, $strVars);

            return $res;
        } else {
            return "Record not Found";
        }
    }

}
