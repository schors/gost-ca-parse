package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"
	"time"
)

type TCert struct {
	Data      string `xml:"Данные"`
	NotBefore string `xml:"ПериодДействияС"`
	NotAfter  string `xml:"ПериодДействияДо"`
}

type TKey struct {
	Id    string  `xml:"ИдентификаторКлюча"`
	Certs []TCert `xml:"Сертификаты>ДанныеСертификата"`
}

type TSWHWSystem struct {
	Alias string `xml:"Псевдоним"`
	Keys  []TKey `xml:"КлючиУполномоченныхЛиц>Ключ"`
}

type TCertificateAuthority struct {
	Name        string        `xml:"Название"`
	SWHWSystems []TSWHWSystem `xml:"ПрограммноАппаратныеКомплексы>ПрограммноАппаратныйКомплекс"`
}

type TStat struct {
	MaxSWHWs     int
	MaxKeys      int
	MaxCerts     int
	MaxSWHWsName string
	MaxKeysName  string
	MaxCertsName string
}

func main() {
	var caVersion, caDateString string
	var caDate time.Time
	var stat TStat

	caCertsDir := flag.String("d", "certs", "Result directory")
	caXMLfilename := flag.String("x", "CA.xml", "Gosuslugi XML file")
	caFilename := flag.String("c", "ca-certificates.pem", "Full CA filename")

	flag.Parse()

	argsWithoutProg := flag.Args()
	if len(argsWithoutProg) > 0 {
		caXMLfilename = &argsWithoutProg[0]
	}
	if _fstat, err := os.Stat(*caCertsDir); os.IsNotExist(err) {
		fmt.Printf("Directory: %s is not exist: %s\n", *caCertsDir, err.Error())
		os.Exit(1)
	} else {
		if !_fstat.IsDir() {
			fmt.Printf("File: %s is not directory\n", *caCertsDir)
			os.Exit(1)
		} else {
			files, err := ioutil.ReadDir(*caCertsDir)
			if err != nil {
				fmt.Printf("Can't read directory: %s\n", *caCertsDir)
				os.Exit(1)
			} else if len(files) > 0 {
				fmt.Printf("Directory: %s is not empty\n", *caCertsDir)
				os.Exit(1)
			}

		}
	}
	caXML, err := os.Open(*caXMLfilename)
	if err != nil {
		fmt.Println("Error opening file:", err)
		os.Exit(2)
	}
	defer caXML.Close()
	caCerts, err := os.OpenFile(*caCertsDir+"/"+*caFilename, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
	if err != nil {
		fmt.Println("Error opening file:", err)
		os.Exit(2)
	}
	defer caCerts.Close()
	decoder := xml.NewDecoder(caXML)
	for {
		t, err := decoder.Token()
		if t == nil {
			if err != io.EOF {
				fmt.Printf("Error: %s\n", err.Error())
				os.Exit(3)
			}
			break
		}
		switch _e := t.(type) {
		case xml.StartElement:
			_name := _e.Name.Local
			switch _name {
			case "Версия":
				var v string
				err := decoder.DecodeElement(&v, &_e)
				if err != nil {
					fmt.Printf("Decode Error: %s\n", err.Error())
					os.Exit(4)
				} else {
					caVersion = v
					fmt.Printf("%v\n", caVersion)
				}
			case "Дата":
				var v string
				err := decoder.DecodeElement(&v, &_e)
				if err != nil {
					fmt.Printf("Decode Error: %s\n", err.Error())
					os.Exit(4)
				} else {
					caDate, err = time.Parse(time.RFC3339, v)
					if err != nil {
						fmt.Printf("Date parse Error: %s\n", err.Error())
						os.Exit(4)
					} else {
						caDateString = v
						fmt.Printf("%s %d\n", caDateString, int(caDate.Unix()))
					}
				}
			case "УдостоверяющийЦентр":
				var ca TCertificateAuthority
				var cswhw, ckey, ccrt int
				err := decoder.DecodeElement(&ca, &_e)
				if err != nil {
					fmt.Printf("Decode Error: %s\n", err.Error())
					os.Exit(4)
				} else {
					fmt.Printf("%s\n", ca.Name)
					for _, swhw := range ca.SWHWSystems {
						fmt.Printf("\t%s\n", swhw.Alias)
						cswhw++
						for _, key := range swhw.Keys {
							fmt.Printf("\t\t%s\n", key.Id)
							ckey++
							for _, crt := range key.Certs {
								_name := fmt.Sprintf("%s_%s_%s", swhw.Alias, crt.NotBefore, crt.NotAfter)
								_name = strings.Replace(_name, "«", "_", -1)
								_name = strings.Replace(_name, "»", "_", -1)
								_name = strings.Replace(_name, "\"", "_", -1)
								_name = strings.Replace(_name, " ", "_", -1)
								_name = strings.Replace(_name, ":", "-", -1)
								_name = strings.Replace(_name, "(", "_", -1)
								_name = strings.Replace(_name, ")", "_", -1)
								if len([]byte(_name)) > 200 {
									_name = _name[:200]
								}
								_name += ".pem"
								_cert := "-----BEGIN CERTIFICATE-----\n"
								for i := 76; i-76 < len(crt.Data); i += 76 {
									if i > len(crt.Data) {
										_cert += crt.Data[i-76:] + "\n"
									} else {
										_cert += crt.Data[i-76:i] + "\n"
									}
								}
								_cert += "-----END CERTIFICATE-----\n"
								_, err = caCerts.Write([]byte(_cert))
								if err != nil {
									fmt.Printf("Write Error: %s\n", err.Error())
									os.Exit(4)
								}
								f, err := os.OpenFile(*caCertsDir+"/"+_name, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
								if err != nil {
									fmt.Println("Error opening file:", err)
									os.Exit(4)
								}
								defer f.Close()
								_, err = f.Write([]byte(_cert))
								if err != nil {
									fmt.Printf("Write Error: %s\n", err.Error())
									os.Exit(4)
								}
								err = f.Sync()
								if err != nil {
									fmt.Printf("Write Error: %s\n", err.Error())
									os.Exit(4)
								}
								f.Close()
								fmt.Printf("\t\t\t%s : %s - %s\n", _name, crt.NotBefore, crt.NotAfter)
								ccrt++
							}
							if stat.MaxCerts < ccrt {
								stat.MaxCerts = ccrt
								stat.MaxCertsName = ca.Name
								ccrt = 0
							}
						}
						if stat.MaxKeys < ckey {
							stat.MaxKeys = ckey
							stat.MaxKeysName = ca.Name
							ckey = 0
						}
					}
					if stat.MaxSWHWs < cswhw {
						stat.MaxSWHWs = cswhw
						stat.MaxSWHWsName = ca.Name
					}
				}
			}
		default:
			//fmt.Printf("%v\n", _e)
		}
	}
	fmt.Printf("\nMaxSWHW = %d (%s), MaxKeys = %d (%s), MaxCerts = %d (%s)\n", stat.MaxSWHWs, stat.MaxSWHWsName, stat.MaxKeys, stat.MaxKeysName, stat.MaxCerts, stat.MaxCertsName)
}
