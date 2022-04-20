
import UIKit
import SQLite3

class DisplayProductViewController: UIViewController {
    
    //MARK: Outlet
    @IBOutlet weak var productCV: UICollectionView!
    
    private var isBookmarkSwitchOn = false
    //MARK: Global Variables
    var productArray: [ProductModel] = []
    var dbDetailsObject: OpaquePointer?
    let tableNameProducts = "Products"
    let databaseName = "bitcode.sqlite" //Step 3 - create Database Name
    
    
    //MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        openCreateDatabase()
        createSwitchBarButton()
        self.title = "Data from the File Directory"
        collectionViewCellRegistration()
        collectionViewConstrains()
        
        productCV.dataSource = self
        productCV.delegate = self
        
        fetchDataFromDBAndLoadCollectionView()
    }
    
    private func fetchDataFromDBAndLoadCollectionView() {
        productArray = readData()
        productCV.reloadData()
    }
    
    private func callAPIDataBase() {
        // 1. Create request of GET type
        let urlString = "https://fakestoreapi.com/products"
        guard let url = URL(string: urlString) else {
            print("Invaild URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Step2: Create session object
        let session = URLSession(configuration: .default)
        
        // Step3: Create Data task
        let dataTask = session.dataTask(with: url) { data, response, error in
            if error == nil { // No Error
                guard let data = data else {
                    print("Data is Nil")
                    return
                }
                
                do {
                    guard let productsArray = try JSONSerialization.jsonObject(with: data) as? [[String:Any]] else {
                        print("Invalid JSON")
                        return
                    }
                    
                    
                    for productDictionary in productsArray {
                        let pId = productDictionary["id"] as? Int
                        let pTitle = productDictionary["title"] as? String
                        let pPrice = productDictionary["price"] as? Double
                        let pDescription = productDictionary["description"] as? String
                        let pCategory = productDictionary["category"] as? String
                        let pRating = productDictionary["rating"] as? [String:Any]
                        let pRate = pRating?["rate"] as? Double
                        let pCount = pRating?["count"] as? Int
                        
                        let urlString = productDictionary["image"] as? String ?? ""
                        let pImageUrl = URL(string: urlString)
                        
                        let product = ProductModel(id: pId ?? 0,
                                                   title: pTitle ?? "Invalid",
                                                   price: pPrice ?? 0,
                                                   descrition: pDescription ?? "Invalid",
                                                   category: pCategory ?? "Invalid",
                                                   rating: pRating ?? [:],
                                                   rate: pRate ?? 0,
                                                   count: pCount ?? 0,
                                                   imageUrl: pImageUrl,
                                                   image: nil)
                        
                        self.productArray.append(product)
                    }
                    
                    DispatchQueue.main.async {
                        self.productCV.reloadData()
                    }
                    
                } catch {
                    print(error.localizedDescription)
                }
                print(data)
            } else {
                print("We have error: \(error?.localizedDescription ?? "")")
            }
            
        }
        // Step4: Call API
        dataTask.resume()
        
    }
    
    //MARK: Collection View Cell Register
    private func collectionViewCellRegistration() {
        let productCollectionViewCellXib = UINib(nibName: "ProductCollectionViewCell", bundle: .main)
        productCV.register(productCollectionViewCellXib, forCellWithReuseIdentifier: "ProductCollectionViewCell")
    }
    
    //MARK: Create Navigation Bar Button
    private func createSwitchBarButton() {
        
        let customSwitch = UISwitch()
        customSwitch.isOn = false
        customSwitch.setOn(false, animated: true)
        
        customSwitch.addTarget(self, action: #selector(self.switchTarget(sender:)), for: .valueChanged)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: customSwitch)
    }
    
    //MARK: Button Action
    @objc func switchTarget(sender: UISwitch!)
    {
        if sender.isOn {
            clearCollectionViewData()
            isBookmarkSwitchOn = true
            self.title = "Data from API"
            callAPIDataBase()
        } else{
            clearCollectionViewData()
            isBookmarkSwitchOn = false
            self.title = "Data from the File Directory"
            productArray = readData()
        }
    }
    
    private func clearCollectionViewData() {
        productArray.removeAll()
        productCV.reloadData()
    }
    
    private func collectionViewConstrains() {
        productCV.topAnchor.constraint(equalTo: view.topAnchor, constant: 85).isActive = true
        productCV.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        productCV.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        productCV.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5).isActive = true
        
    }
    
    //MARK: Read From Data Base
    private func readData() -> [ProductModel] {
        var readStatement: OpaquePointer?
        let readQuery = "SELECT * FROM \(tableNameProducts)"
        
        var products = [ProductModel]()
        
        if sqlite3_prepare_v2(self.dbDetailsObject,
                              readQuery,
                              -1,
                              &readStatement,
                              nil) == SQLITE_OK {
            print("Read Query Compiled Successfully")
            while sqlite3_step(readStatement) == SQLITE_ROW {
                //(ID INTEGER PRIMARY KEY, Title TEXT,Price DOUBLE,Description TEXT,Category TEXT,Image BLOB,Rate DOUBLE, Count INTEGER)
                print("Read Query executed successfully")
                let idInt32 = sqlite3_column_int(readStatement, 0)
                let id = Int(idInt32)
                let price = sqlite3_column_double(readStatement, 2)
                let rate = sqlite3_column_double(readStatement, 6)
                let countInt32 = sqlite3_column_int(readStatement, 7)
                let count = Int(countInt32)
                guard
                    let titleCStr = sqlite3_column_text(readStatement, 1),
                    let descriptionCStr = sqlite3_column_text(readStatement, 3),
                    let categoryCStr = sqlite3_column_text(readStatement, 4)
                        //  let image = sqlite3_column_blob(readStatement, 5)
                else {
                    return [ProductModel]()
                }
                let title = String(cString: titleCStr)
                let description = String(cString: descriptionCStr)
                let category = String(cString: categoryCStr)
                //(ID INTEGER PRIMARY KEY, Title TEXT,Price DOUBLE,Description TEXT,Category TEXT,Image BLOB,Rate DOUBLE, Count INTEGER)
                print("Product Details:\nId: \(id),\nTitle:\(title),\nDescription: \(description),\nPrice: \(price),\nR: \(price),\nCategory: \(category),\nRate: \(rate),\nCount: \(count)")
                
                let product = ProductModel(id: id, title: title, price: price, descrition: description, category: category, rating: [:], rate: rate, count: count, imageUrl: nil, image: nil)
                products.append(product)
                
            }
            return products
        } else {
            print("Read Query Compilation Failed")
            return [ProductModel]()
        }
    }
    
    //MARK: Step 2 - Create DataBase
    private func openCreateDatabase() {
        guard let dbPath = getPathForDocumentsDirectory() else{
            print("Documents Directory Path is Missing")
            return
        }
        print("DB Path: \(dbPath)")
        
        //Step2.1 - Importing SQLite3 and To check Database is Created or already present (bitcode.sqlite)
        var dbdetails: OpaquePointer?
        if sqlite3_open(dbPath,
                        &dbdetails) == SQLITE_OK { /* Sqlite Ok used to check the query condition*/
            print("Database is successfully created Or Already Present & we are able to access it/Open it")
            self.dbDetailsObject = dbdetails
        } else {
            print("Unable to Create Or Open DB")
            
        }
    }
    
    
    //MARK: Step 1 - To Get Path For Documents Directory
    private func getPathForDocumentsDirectory() -> String? {
        do{
            // Use to access Document Directory
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory,
                                                                   in: .userDomainMask,
                                                                   appropriateFor: nil,
                                                                   create: false)
            // To check where the Database is in documents Directory
            let dbPath = documentDirectoryURL.appendingPathComponent(self.databaseName)
            return dbPath.absoluteString
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
    }
    
}

// MARK: UICollectionViewDataSource
extension DisplayProductViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        productArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = "ProductCollectionViewCell"
        guard let cell = self.productCV.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ProductCollectionViewCell
        else {
            return UICollectionViewCell()
        }
        let productIndex = productArray[indexPath.row]
        cell.productName.text = productIndex.title
        cell.productPrice.text = "\(productIndex.price)"
        cell.layer.cornerRadius = 10
        
        cell.backgroundColor = isBookmarkSwitchOn ? .orange : .green

        return cell
    }
    
}
//MARK: UICollectionViewDelegateFlowLayout
extension DisplayProductViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 196.0, height: 110.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "ProductDetailViewController") as? ProductDetailViewController {
            vc.product = productArray[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("VC not found")
        }
    }
}
