<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

/*
    Service controls
    Date Created: September 8, 2016

*/
$currDir = dirname(__FILE__);

include_once $currDir . '/../globals.php';

if(!class_exists('DataActionLogger'))
{
    require_once dirname(__FILE__) . '/../../libs/logger/dataActionLogger.php';
}

class Service
{
    public $siteRoot = '';

    private $db;

    private $login;

    private $dataActionLogger;

    public function __construct($db, $login)
    {
        $this->db = $db;
        $this->login = $login;
        $this->dataActionLogger = new \DataActionLogger($db, $login);

        // For Jira Ticket:LEAF-2471/remove-all-http-redirects-from-code
//        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on' ? 'https' : 'http';
        $protocol = 'https';
        $this->siteRoot = "{$protocol}://" . HTTP_HOST . dirname($_SERVER['REQUEST_URI']) . '/';
    }

    public function addService($groupName, $parentGroupID = null)
    {
        if (!$this->login->checkGroup(1))
        {
            return 'Admin access required';
        }

        $groupName = trim($groupName);

        if ($groupName == '')
        {
            return 'Name cannot be blank';
        }
        $newID = -99;
        $res = $this->db->prepared_query('SELECT * FROM services
											WHERE serviceID < 0
											ORDER BY serviceID ASC', array());
        if (isset($res[0]['serviceID']))
        {
            $newID = $res[0]['serviceID'] - 1;
        }
        else
        {
            $newID = -1;
        }

        if (!is_null($parentGroupID))
        {
            $parentGroupID = (int)$parentGroupID;
        }
        $sql_vars = array(':serviceID' => (int)$newID,
                      ':service' => $groupName,
                      ':groupID' => $parentGroupID, );
        $res = $this->db->prepared_query("INSERT INTO services (serviceID, service, abbreviatedService, groupID)
                                            VALUES (:serviceID, :service, '', :groupID)", $sql_vars);

        return $newID;
    }

    public function removeService($groupID)
    {
        if (!$this->login->checkGroup(1))
        {
            return 'Admin access required';
        }
        $sql_vars = array(':groupID' => $groupID);
        $this->db->prepared_query('DELETE FROM services WHERE serviceID=:groupID', $sql_vars);
        $this->db->prepared_query('DELETE FROM service_chiefs WHERE serviceID=:groupID', $sql_vars);

        return 1;
    }

    public function addMember($groupID, $member)
    {
        include_once __DIR__ . '/../' . Config::$orgchartPath . '/sources/Employee.php';

        $config = new Config();
        $db_phonebook = new DB($config->phonedbHost, $config->phonedbUser, $config->phonedbPass, $config->phonedbName);
        $employee = new Orgchart\Employee($db_phonebook, $this->login);

        if (is_numeric($groupID) && $member != '')
        {
            $sql_vars = array(':userID' => $member,
                    ':serviceID' => $groupID,);

            // Update on duplicate keys
            $this->db->prepared_query('INSERT INTO service_chiefs (serviceID, userID, backupID, locallyManaged, active)
                                                    VALUES (:serviceID, :userID, null, 1, 1)
                                                    ON DUPLICATE KEY UPDATE serviceID=:serviceID, userID=:userID, backupID=null, locallyManaged=1, active=1', $sql_vars);

            $this->dataActionLogger->logAction(\DataActions::ADD, \LoggableTypes::SERVICE_CHIEF, [
                new LogItem("service_chiefs","serviceID", $groupID, $this->getServiceName($groupID)),
                new LogItem("service_chiefs", "userID", $member, $this->getEmployeeDisplay($member)),
                new LogItem("service_chiefs", "locallyManaged", "false")
            ]);

            // check if this service is also an ELT
            $sql_vars = array(':groupID' => $groupID);
            $res = $this->db->prepared_query('SELECT * FROM services
   												WHERE serviceID=:groupID', $sql_vars);
            // if so, update groups table
            if ($res[0]['groupID'] == $groupID)
            {
                $sql_vars = array(':userID' => $member,
                              ':groupID' => $groupID, );
                $this->db->prepared_query('INSERT INTO users (userID, groupID)
                                                VALUES (:userID, :groupID)', $sql_vars);
            }

            // include the backups of employees
            $emp = $employee->lookupLogin($member);
            $backups = $employee->getBackups($emp[0]['empUID']);
            foreach ($backups as $backup) {
                $sql_vars = array(':userID' => $backup['userName'],
                    ':serviceID' => $groupID,
                    ':backupID' => $emp[0]['userName'],);

                $res = $this->db->prepared_query('SELECT * FROM service_chiefs WHERE userID=:userID AND serviceID=:serviceID', $sql_vars);

                // Check for locallyManaged users
                if ($res[0]['locallyManaged'] == 1) {
                    $sql_vars[':backupID'] = null;
                } else {
                    $sql_vars[':backupID'] = $emp[0]['userName'];
                }
                // Add backupID check for updates
                $this->db->prepared_query('INSERT INTO service_chiefs (userID, serviceID, backupID)
                                                    VALUES (:userID, :serviceID, :backupID)
                                                    ON DUPLICATE KEY UPDATE userID=:userID, serviceID=:serviceID, backupID=:backupID', $sql_vars);
            }
        }

        return 1;
    }

    public function removeMember($groupID, $member)
    {
        include_once __DIR__ . '/../' . Config::$orgchartPath . '/sources/Employee.php';

        $config = new Config();
        $db_phonebook = new DB($config->phonedbHost, $config->phonedbUser, $config->phonedbPass, $config->phonedbName);
        $employee = new Orgchart\Employee($db_phonebook, $this->login);

        if (is_numeric($groupID) && $member != '')
        {
            $sql_vars = array(':userID' => $member,
                          ':groupID' => $groupID, );

            $this->dataActionLogger->logAction(\DataActions::DELETE,\LoggableTypes::SERVICE_CHIEF,[
                new LogItem("service_chiefs","serviceID", $groupID, $this->getServiceName($groupID)),
                new LogItem("service_chiefs", "userID", $member, $this->getEmployeeDisplay($member))
            ]);

            $this->db->prepared_query('DELETE FROM service_chiefs WHERE userID=:userID AND serviceID=:groupID', $sql_vars);

            // check if this service is also an ELT
            $sql_vars = array(':groupID' => $groupID);
            $res = $this->db->prepared_query('SELECT * FROM services
   												WHERE serviceID=:groupID', $sql_vars);
            // if so, update groups table
            if ($res[0]['groupID'] == $groupID)
            {
                $sql_vars = array(':userID' => $member,
                        ':groupID' => $groupID, );
                $this->db->prepared_query('DELETE FROM users
    										WHERE userID=:userID
    											AND groupID=:groupID', $sql_vars);
            }

            // include the backups of employee
            $emp = $employee->lookupLogin($member);
            $backups = $employee->getBackups($emp[0]['empUID']);
            foreach ($backups as $backup) {
                $sql_vars = array(':userID' => $backup['userName'],
                    ':serviceID' => $groupID,
                    ':backupID' => $member,);

                $res = $this->db->prepared_query('SELECT * FROM service_chiefs WHERE userID=:userID AND serviceID=:serviceID AND backupID=:backupID', $sql_vars);

                // Check for locallyManaged users
                if ($res[0]['locallyManaged'] == 0) {
                    $this->db->prepared_query('DELETE FROM service_chiefs WHERE userID=:userID AND serviceID=:serviceID AND backupID=:backupID', $sql_vars);
                }
            }
        }

        return 1;
    }

    public function getMembers($groupID)
    {
        if (!is_numeric($groupID))
        {
            return;
        }
        $sql_vars = array(':groupID' => $groupID);
        $res = $this->db->prepared_query('SELECT * FROM service_chiefs WHERE serviceID=:groupID ORDER BY userID', $sql_vars);

        $members = array();
        if (count($res) > 0)
        {
            require_once '../VAMC_Directory.php';
            $dir = new VAMC_Directory();
            foreach ($res as $member)
            {
                $dirRes = $dir->lookupLogin($member['userID']);

                if (isset($dirRes[0]))
                {
                    $temp = $dirRes[0];
                    if($member['locallyManaged'] == 1) {
                        $temp['backupID'] = null;
                    } else {
                        $temp['backupID'] = $member['backupID'];
                    }
                    $temp['locallyManaged'] = $member['locallyManaged'];
                    $temp['active'] = $member['active'];
                    $members[] = $temp;
                }
            }
        }

        return $members;
    }

    public function getQuadrads()
    {
        $res = $this->db->prepared_query('SELECT groupID, name FROM services
    								LEFT JOIN groups USING (groupID)
    								WHERE groupID IS NOT NULL
    								GROUP BY groupID
    								ORDER BY name', array());

        return $res;
    }

    public function getGroups()
    {
        $res = $this->db->prepared_query('SELECT * FROM services ORDER BY service ASC', array());

        return $res;
    }

    public function getGroupsAndMembers()
    {
        $groups = $this->getGroups();

        $list = array();
        foreach ($groups as $group)
        {
            $group['members'] = $this->getMembers($group['serviceID']);
            $list[] = $group;
        }

        return $list;
    }

    /**
     * Gets Employee name formatted for display
     * @param string $employeeID 	the id of the employee to retrieve display name
     * @return string
     */
    private function getEmployeeDisplay($employeeID)
    {
        require_once '../VAMC_Directory.php';

        $dir = new VAMC_Directory();
        $dirRes = $dir->lookupLogin($employeeID);

        $empData = $dirRes[0];
        $empDisplay = $empData["firstName"] . " " . $empData["lastName"];

        return $empDisplay;
    }

    /**
     * Gets display name for Service.
     * @param int $serviceID 	the id of the service to find display name for.
     * @return string
     */
    public function getServiceName($serviceID)
    {
        $sql_vars = array(':serviceID' => $serviceID);
        return $this->db->prepared_query('SELECT * FROM services
                                            where serviceid=:serviceID', $sql_vars)[0]['service'];
    }

    /**
     * Gets history for given serviceID.
     * @param int $filterById 	the id of the service to fetch logs of
     * @return array
     */
    public function getHistory($filterById)
    {
        return $this->dataActionLogger->getHistory($filterById, "serviceID", \LoggableTypes::SERVICE_CHIEF);
    }
}
